# Lesson 2: Data Prefetch Trade-offs (Resolver vs. In-Component)

When a user navigates to a route, you often need to fetch data for that route from an API. A key architectural decision is *when* to initiate that data fetch. There are two primary patterns in Angular:

1.  **Using a Resolver:** Fetch the data *before* the route fully activates. The navigation is blocked until the data arrives.
2.  **In-Component Fetching:** Activate the route immediately, show a loading state in the component, and then fetch the data from within the component's logic (e.g., in `ngOnInit` or the `constructor`).

Historically, resolvers were a popular pattern, but the modern consensus strongly favors **in-component fetching** for a better user experience. This lesson explores the trade-offs.

- **Key Resource:** [Are Angular Resolvers Still Worth It? A Comprehensive Guide](https://medium.com/@vigenhovhannisiano/are-angular-resolvers-still-worth-it-a-comprehensive-guide-e03789446318)

---

## Pattern 1: The Resolver (Blocking Navigation)

A resolver is a function or class that runs during the navigation process. The router waits for the resolver's observable to complete before activating the component.

### How it Works

**1. The Resolver Function:**
```typescript
// product.resolver.ts
import { inject } from '@angular/core';
import { ResolveFn } from '@angular/router';
import { ProductService } from './product.service';
import { Product } from './product.model';

export const productResolver: ResolveFn<Product> = (route, state) => {
  const productService = inject(ProductService);
  const id = route.paramMap.get('id')!;
  // The router will wait for this observable to complete.
  return productService.getProductById(id);
};
```

**2. The Route Configuration:**
```typescript
// routes.ts
{
  path: 'products/:id',
  component: ProductDetailsComponent,
  resolve: {
    product: productResolver // The key 'product' is where the data will be placed.
  }
}
```

**3. Accessing the Data:**
```typescript
// product-details.component.ts
export class ProductDetailsComponent implements OnInit {
  product: Product;
  constructor(private route: ActivatedRoute) {}

  ngOnInit() {
    // The data is already there when the component initializes.
    this.product = this.route.snapshot.data['product'];
  }
}
```

### Trade-offs of Resolvers

-   **Pro: No Component Loading State:** The component doesn't need to manage its own `isLoading` flag, as the data is guaranteed to be present on initialization.
-   **Con: POOR USER EXPERIENCE:** This is the biggest drawback. If the API call takes 2 seconds, the user is stuck looking at the *previous page* (or a blank screen) for 2 seconds with no feedback that their navigation is in progress. The application feels frozen and unresponsive.
-   **Con: Complex Error Handling:** If the resolver fails (e.g., a 404 Not Found), the navigation is canceled entirely. The user is left on the previous page with no context. Handling this gracefully often requires complex logic in a global error handler to redirect the user to a "Not Found" page.
-   **Con: No Cancellation:** If the user gets impatient and clicks another link while the resolver is running, the HTTP request continues in the background, wasting resources.

---

## Pattern 2: In-Component Fetching (Non-Blocking)

This is the modern, recommended approach. The navigation happens instantly, the component displays a loading state, and then fetches the data.

### How it Works

```typescript
// product-details.component.ts
import { Component, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { ProductService } from './product.service';
import { switchMap, map, filter } from 'rxjs/operators';
import { toSignal } from '@angular/core/rxjs-interop';

@Component({
  selector: 'app-product-details',
  template: `
    <div *ngIf="product(); else loading">
      <h2>{{ product()?.name }}</h2>
      <!-- ... product details ... -->
    </div>
    <ng-template #loading>
      <p>Loading product...</p>
    </ng-template>
  `
})
export class ProductDetailsComponent {
  private route = inject(ActivatedRoute);
  private productService = inject(ProductService);

  // A declarative stream that handles the entire data fetching lifecycle.
  private product$ = this.route.paramMap.pipe(
    map(params => params.get('id')),
    filter(id => !!id), // Ensure ID is not null
    // switchMap handles cancellation automatically if the user navigates away.
    switchMap(id => this.productService.getProductById(id!))
  );

  // Convert to a signal for easy, reactive use in the template.
  product = toSignal(this.product$);
}
```

### Trade-offs of In-Component Fetching

-   **Pro: EXCELLENT USER EXPERIENCE:** Navigation is instantaneous. The user immediately sees the new page with a loading indicator, providing clear feedback that the application is working. This makes the app feel fast and responsive.
-   **Pro: Graceful Error Handling:** Errors can be handled directly in the stream (e.g., with `catchError`). You can easily show an error message within the component's view instead of abruptly canceling the navigation.
-   **Pro: Automatic Cancellation:** Using `switchMap` on the route parameters means that if the user navigates away before the data arrives, the previous HTTP request is automatically canceled. This is efficient and prevents race conditions.
-   **Con: Component Manages Loading State:** The component is responsible for showing a loading/error/success state. However, with reactive patterns like in the example above, this is often trivial to implement.

## Conclusion

| Feature             | Resolver (Blocking)                               | In-Component (Non-Blocking)                                       |
| ------------------- | ------------------------------------------------- | ----------------------------------------------------------------- |
| **User Experience** | Poor (Feels frozen)                               | **Excellent** (Feels responsive)                                  |
| **Error Handling**  | Complex (Navigation fails)                        | **Simple** (Handled in stream, shown in component view)           |
| **Cancellation**    | Difficult                                         | **Automatic** (with `switchMap`)                                  |
| **Recommendation**  | Avoid for primary data fetching.                  | **Strongly Recommended** for almost all route-based data fetching. |

For a modern, high-performance SPA, favor **in-component data fetching**. It provides a superior user experience and a more robust, declarative, and maintainable pattern for developers.