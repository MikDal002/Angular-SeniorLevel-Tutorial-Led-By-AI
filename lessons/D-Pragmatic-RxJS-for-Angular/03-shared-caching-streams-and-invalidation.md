# Lesson 3: Shared Caching Streams and Invalidation

In many applications, the same piece of data (e.g., the current user's profile, a list of products) is needed by multiple components. Making a separate HTTP request for this data in each component is inefficient and can lead to performance issues and inconsistent state.

A powerful pattern to solve this is to create a **shared, caching data stream** in a service. This ensures that the HTTP request is only made once, and all subsequent subscribers get the cached result. We also need a way to manually invalidate this cache to fetch fresh data when needed.

- **Key Resource:** [RxJS Caching and Refreshing in Angular by Preston Lamb](https://www.prestonlamb.com/blog/rxjs-cache-and-refresh-in-angular/)

## The Core Pattern: `shareReplay`

The `shareReplay` operator is the foundation of this pattern. It multicasts the source observable, meaning all subscribers share a single underlying subscription. It also replays a specified number of previous emissions to new subscribers.

-   **`shareReplay({ bufferSize: 1, refCount: true })`**: This is the modern, recommended configuration.
    -   `bufferSize: 1`: Caches and replays the last emitted value.
    -   `refCount: true`: This is crucial. It means the underlying subscription to the source (e.g., the `HttpClient` call) is only created when the *first* subscriber arrives, and it is torn down when the *last* subscriber unsubscribes. This prevents memory leaks and keeps the cache "live" only as long as it's needed.

**Simple Caching Example:**
```typescript
// products.service.ts
@Injectable({ providedIn: 'root' })
export class ProductsService {
  private products$ = this.httpClient.get<Product[]>('/api/products').pipe(
    shareReplay({ bufferSize: 1, refCount: true })
  );

  getProducts() {
    return this.products$;
  }
}
```
Any component that calls `productsService.getProducts()` and subscribes will share the same stream. The HTTP request is only made once (when the first component subscribes), and all other components get the cached array of products.

- **Resource:** [Official `shareReplay` Documentation](https://rxjs.dev/api/operators/shareReplay)

## Adding Manual Invalidation (The "Refresh" Pattern)

The simple cache is great, but what if the data changes on the server? We need a way to tell our service to discard the cache and fetch the data again. We can achieve this by introducing a "refresh" `Subject`.

The pattern looks like this:
1.  Create a `Subject` that will act as our refresh trigger.
2.  Use `startWith` to make the stream emit immediately on the first subscription.
3.  Use `switchMap` to trigger the actual data fetch (the HTTP request). Every time the refresh subject emits, `switchMap` will cancel any pending request and start a new one.
4.  Pipe the result into `shareReplay` to create the shared, caching effect.

### Example: A Cache with a Refresh Button

Let's build a `ProductsService` that exposes a list of products and a `refresh()` method.

```typescript
// products.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject, of } from 'rxjs';
import { switchMap, startWith, shareReplay, tap } from 'rxjs/operators';
import { Product } from './product.model';

@Injectable({ providedIn: 'root' })
export class ProductsService {
  private httpClient = inject(HttpClient);

  // 1. A Subject to trigger the refresh.
  private refresh$ = new Subject<void>();

  // The stream that makes the actual HTTP request.
  private productsHttp$ = this.httpClient.get<Product[]>('/api/products').pipe(
    tap(() => console.log('Fetched products from API'))
  );

  // 2. The main data stream.
  products$ = this.refresh$.pipe(
    // 3. Emit immediately on subscription.
    startWith(undefined), // The value here doesn't matter, it just triggers the pipe.
    // 4. On each emission, switch to the HTTP request stream.
    switchMap(() => this.productsHttp$),
    // 5. Share and replay the result.
    shareReplay({ bufferSize: 1, refCount: true })
  );

  /**
   * Call this method to manually trigger a refresh of the product data.
   */
  refresh() {
    this.refresh$.next();
  }
}
```

**How it works:**
-   A component subscribes to `productsService.products$`.
-   `startWith` immediately triggers the `switchMap`.
-   `switchMap` subscribes to `productsHttp$`, which makes the API call. The result is cached by `shareReplay`.
-   Another component subscribes. `shareReplay` gives it the cached result instantly without a new API call.
-   Someone calls `productsService.refresh()`.
-   The `refresh$` subject emits a new value.
-   This triggers `switchMap` again, which cancels any pending fetch and subscribes to `productsHttp$` again, making a fresh API call.
-   The new result is broadcast to all subscribers and cached by `shareReplay`.

---

## ✅ Verifiable Outcome

You can verify that the caching and invalidation pattern is working correctly by using the browser's developer tools.

1.  **Implement the Service:**
    -   Create the `ProductsService` as described in the lesson.
    -   You will need to use `HttpClientTestingModule` and `HttpTestingController` to mock the backend response for `/api/products`.

2.  **Create a UI:**
    -   Create two separate components (`ComponentA` and `ComponentB`) that both inject `ProductsService` and subscribe to the `products$` observable in their templates using the `async` pipe.
    -   Create a third component that has a "Refresh" button which calls the `productsService.refresh()` method.
    -   Display all three components on the same page.

3.  **Test the Initial Cache:**
    -   Run the application and open the DevTools "Network" tab.
    -   **Expected Result:** You should see **only one** request go out to `/api/products`. Both `ComponentA` and `ComponentB` should display the product data. This proves that the stream is being shared and the result is cached.

4.  **Test the Invalidation:**
    -   Click the "Refresh" button.
    -   **Expected Result:** You should see **a single new** request go out to `/api/products` in the Network tab. Both components will update with the new data (if your mock provides a different response on the second call), confirming that the cache was successfully invalidated and the new value was broadcast to all subscribers.