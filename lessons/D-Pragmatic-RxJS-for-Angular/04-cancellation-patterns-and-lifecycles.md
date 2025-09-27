# Lesson 4: Cancellation Patterns and Lifecycles

In a dynamic single-page application, users can navigate quickly, and components are constantly being created and destroyed. It's critical to ensure that any long-running asynchronous work (like HTTP requests) initiated by a component is automatically canceled when it's no longer needed.

Failing to do so can lead to bugs, race conditions, and wasted resources. For example:
-   A user navigates to a product page, which starts an HTTP request.
-   Before the request completes, they navigate to another product page.
-   The first request eventually completes and updates the view with the wrong product's data.

This lesson covers the two primary RxJS patterns for tying the lifecycle of an observable to the lifecycle of your components and navigation events.

## Pattern 1: `takeUntilDestroyed` for Component-Level Cleanup

This is the most fundamental cancellation pattern. As covered in a previous lesson, the `takeUntilDestroyed` operator links an observable's lifetime directly to the component that subscribes to it. When the component is destroyed (which happens when you navigate away from the route that renders it), the subscription is automatically completed and cleaned up.

This is the go-to solution for any observable work that is initiated within a component's class logic (e.g., in `ngOnInit`).

### Example: A Component That Fetches Data

```typescript
// my-component.ts
import { Component, OnInit, inject } from '@angular/core';
import { DataService } from './data.service';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

@Component({ /* ... */ })
export class MyComponent implements OnInit {
  private dataService = inject(DataService);

  constructor() {
    // Using the constructor injection context for takeUntilDestroyed
    this.dataService.getSomeLongRunningData().pipe(
      takeUntilDestroyed() // The subscription will be cancelled when MyComponent is destroyed
    ).subscribe(data => {
      console.log('Data arrived:', data);
      // If the component is already destroyed, this code will never run.
    });
  }
}
```

-   **When to use it:** Always use `takeUntilDestroyed` for imperative subscriptions (`.subscribe()`) made within a component class. It's your primary defense against memory leaks and unwanted side effects from destroyed components.
-   **Resource:** [Unsubscribing with `takeUntilDestroyed`](https://angular.io/guide/rxjs-interop#unsubscribing-with-takeuntildestroyed)

## Pattern 2: `switchMap` for Parameterized Data Streams

A very common scenario is fetching data based on the current route's parameters. When the route parameters change, you want to cancel the old data request and start a new one with the new parameters.

This is the perfect use case for `switchMap`. By piping the `ActivatedRoute.paramMap` observable into a `switchMap`, you create a declarative and automatically-canceling data stream.

### Example: A Product Details Page

```typescript
// product-details.component.ts
import { Component, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { ProductService } from './product.service';
import { switchMap, map, filter } from 'rxjs/operators';
import { toSignal } from '@angular/core/rxjs-interop';

@Component({ /* ... */ })
export class ProductDetailsComponent {
  private route = inject(ActivatedRoute);
  private productService = inject(ProductService);

  // Declarative stream that reacts to route parameter changes.
  private product$ = this.route.paramMap.pipe(
    map(params => params.get('id')),
    filter(id => id !== null), // Ensure the ID exists
    // When the 'id' changes, switchMap cancels the previous HTTP request
    // and starts a new one with the new ID.
    switchMap(id => this.productService.getProductById(id!))
  );

  // Convert the final stream to a signal for easy use in the template.
  product = toSignal(this.product$);
}
```

**How it works:**
1.  The component subscribes to `route.paramMap` to get the current route parameters.
2.  The stream is piped into `switchMap`.
3.  When the component first loads, `switchMap` gets the initial `id` and calls `productService.getProductById(id)`.
4.  The user navigates from `/products/1` to `/products/2`.
5.  The `paramMap` observable emits a new value with the new `id`.
6.  `switchMap` immediately **unsubscribes** from the pending request for product `1` (if it's still in flight) and subscribes to a new `getProductById(2)` observable.

This pattern elegantly handles both the initial data fetch and the cancellation/refetch logic for subsequent navigation within the same component. Because `toSignal` is used, the entire chain is also automatically cleaned up when the component is destroyed.

## Combining the Patterns

These patterns are not mutually exclusive. You can and often will use them together. For instance, you might use `switchMap` to react to route changes and then use `takeUntilDestroyed` within a `tap` operator if you need to perform some imperative, long-running side effect based on the result.

---

## ✅ Verifiable Outcome

You can verify these cancellation patterns using your browser's developer tools.

1.  **Test `takeUntilDestroyed`:**
    -   Create the `MyComponent` from the first example. For the `getSomeLongRunningData` method in your service, use a long delay (e.g., `of('some data').pipe(delay(5000))`).
    -   Create two routes, one for `MyComponent` and one for a different page.
    -   Run the application and navigate to the route for `MyComponent`. Open the DevTools "Network" tab. You will see the (mock) data request is pending.
    -   Before the 5-second delay is over, navigate to the other page.
    -   **Expected Result:** As soon as you navigate away, you should see in the Network tab that the pending request is immediately marked as **`(canceled)`**. This proves that `takeUntilDestroyed` correctly terminated the subscription and the underlying HTTP request when the component was destroyed.

2.  **Test `switchMap`:**
    -   Implement the `ProductDetailsComponent` from the second example. Use a mock `ProductService` that has a delay, similar to the test above.
    -   Create routes for `/products/:id`. Add links to navigate between `/products/1` and `/products/2`.
    -   Run the application and navigate to `/products/1`. You will see the request for product 1 is pending in the Network tab.
    -   Before the request for product 1 completes, click the link to navigate to `/products/2`.
    -   **Expected Result:** You will see the first request for product 1 get canceled in the Network tab, and a new request for product 2 will be initiated. This proves that `switchMap` is correctly canceling the previous request when the route parameter changes.