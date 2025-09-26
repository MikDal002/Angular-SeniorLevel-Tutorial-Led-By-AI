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

This pattern provides a highly efficient and robust way to manage shared data in your application, giving you full control over when and how data is fetched and refreshed, all while preventing the "thundering herd" problem of multiple, simultaneous requests for the same data.