# Lesson 3: Caching Strategies (SWR and cache-control)

Fetching data over the network is slow. A robust caching strategy is essential for a fast, responsive application. This lesson explores two common and powerful caching patterns: the programmatic **Stale-While-Revalidate (SWR)** pattern and the standards-based **`Cache-Control`** header pattern.

## Stale-While-Revalidate (SWR)

SWR is a caching strategy that prioritizes perceived performance. It provides a great user experience by **immediately** returning cached (stale) data, while simultaneously firing off a network request to fetch fresh (revalidate) data. Once the fresh data arrives, the UI is updated.

-   **The User's Perspective:** The user sees the data instantly, so the app feels fast. A moment later, that data might update on their screen with the latest information.
-   **The Goal:** Balance immediacy (showing *something* right away) with freshness (ensuring the data is eventually up-to-date).

- **Resource:** [Keeping things fresh with stale-while-revalidate](https://web.dev/articles/stale-while-revalidate)

### Implementing SWR with RxJS

We can implement the SWR pattern in an Angular service using RxJS. The core idea is to maintain a `BehaviorSubject` to hold the cached data and combine it with a stream that triggers the network request.

```typescript
// products-swr.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { switchMap, tap, share, catchError, startWith } from 'rxjs/operators';
import { Product } from './product.model';

@Injectable({ providedIn: 'root' })
export class ProductsSWRService {
  private httpClient = inject(HttpClient);

  // 1. A subject to hold the cached data.
  // BehaviorSubject ensures new subscribers get the last known value.
  private productsCache$ = new BehaviorSubject<Product[] | null>(null);

  // 2. A trigger to initiate the "revalidate" fetch.
  private revalidate$ = new Subject<void>();

  // 3. The stream that performs the actual HTTP request.
  private fetchProducts$ = this.httpClient.get<Product[]>('/api/products').pipe(
    // When fresh data arrives, update the cache.
    tap(products => this.productsCache$.next(products)),
    // If the fetch fails, we don't want to kill the stream.
    // We just return an empty observable and the cache remains untouched.
    catchError(() => of(null))
  );

  // 4. The main SWR stream.
  products$: Observable<Product[] | null> = this.revalidate$.pipe(
    // 5. Start the stream immediately on first subscription.
    startWith(undefined),
    // 6. Every time a revalidation is triggered...
    switchMap(() => this.fetchProducts$),
    // 7. And also subscribe to the cache itself.
    // This allows us to emit the stale data first, then the fresh data.
    () => this.productsCache$.asObservable()
  ).pipe(
    // 8. Share the stream among all subscribers.
    share()
  );

  /**
   * Call this to trigger a background refresh of the data.
   */
  revalidate() {
    this.revalidate$.next();
  }
}
```
**How to use it:**
A component can subscribe to `products$`. On the first subscription, it will immediately receive `null` (or the last known value) from `productsCache$`, and a background fetch will be initiated. When the fetch completes, `productsCache$` will emit the new value, and the component's view will update. Calling `revalidate()` will trigger the process again.

## HTTP `Cache-Control` Header

A more traditional, standards-based approach to caching is to respect the `Cache-Control` HTTP header sent by the server. This header tells the client how long it's allowed to cache a response.

-   `Cache-Control: public, max-age=3600`: This response can be cached by any cache (browser, CDN) for 3600 seconds (1 hour).

We can build an `HttpInterceptor` to implement a client-side cache that respects this header.

### `Cache-Control` Interceptor

This interceptor will:
1.  Check if a request is cacheable (e.g., it's a `GET` request).
2.  Check if a valid, non-expired response is already in the cache. If so, return it without making an HTTP call.
3.  If not, make the HTTP call.
4.  When the response arrives, inspect its `Cache-Control` header.
5.  If it's cacheable, store the response and its expiration time in the cache.

```typescript
// cache.interceptor.ts
import { Injectable } from '@angular/core';
import {
  HttpEvent, HttpInterceptor, HttpHandler, HttpRequest, HttpResponse
} from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';

interface CacheEntry {
  response: HttpResponse<any>;
  expires: number;
}

@Injectable()
export class CacheInterceptor implements HttpInterceptor {
  private cache = new Map<string, CacheEntry>();

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // Only cache GET requests
    if (req.method !== 'GET') {
      return next.handle(req);
    }

    // Check for a cached response
    const cachedEntry = this.cache.get(req.urlWithParams);
    if (cachedEntry && cachedEntry.expires > Date.now()) {
      return of(cachedEntry.response.clone()); // Return cached response
    }

    return next.handle(req).pipe(
      tap(event => {
        if (event instanceof HttpResponse) {
          const cacheControl = event.headers.get('Cache-Control');
          if (cacheControl && cacheControl.includes('max-age')) {
            const maxAge = /max-age=(\d+)/.exec(cacheControl);
            if (maxAge) {
              const expires = Date.now() + parseInt(maxAge[1], 10) * 1000;
              this.cache.set(req.urlWithParams, { response: event.clone(), expires });
            }
          }
        }
      })
    );
  }
}
```

### SWR vs. `Cache-Control`

| Feature                 | SWR (Programmatic RxJS)                                  | `Cache-Control` (Interceptor)                               |
| ----------------------- | -------------------------------------------------------- | ----------------------------------------------------------- |
| **User Experience**     | Excellent. UI feels instant.                             | Good. Subsequent requests are instant if cache is fresh.    |
| **Data Freshness**      | Data is eventually consistent.                           | Data can be stale up to the `max-age` limit.                |
| **Implementation**      | More complex. Managed per-service with RxJS.             | Simpler. Centralized logic in an interceptor.               |
| **Control**             | Full programmatic control over when to revalidate.       | Controlled by the backend via HTTP headers.                 |
| **Best For**            | Critical UI data where perceived performance is key.     | Static or semi-static data (e.g., config, dropdown lists). |

---

## ✅ Verifiable Outcome

You can verify these caching strategies by observing the "Network" tab in your browser's developer tools.

1.  **Test the SWR Pattern:**
    -   Implement the `ProductsSWRService` and a component that subscribes to its `products$` observable.
    -   Use `HttpTestingController` to mock the response for `/api/products`.
    -   When the component loads, you should see one network request.
    -   Navigate away from the component and then back to it.
    -   **Expected Result:** You should see **no new network request**. The data is served from the `BehaviorSubject` cache. Now, call the `revalidate()` method. You should see a new network request fire, and the UI should update with the new data.

2.  **Test the `Cache-Control` Interceptor:**
    -   Implement the `CacheInterceptor` and provide it in your `app.config.ts`.
    -   Create a component that makes a `GET` request to a public API that you know returns a `Cache-Control` header (or mock one with `HttpTestingController` that has the header).
    -   Trigger the request once.
    -   **Expected Result:** You will see the request in the Network tab.
    -   Trigger the same request a second time immediately.
    -   **Expected Result:** You will **not** see a second request in the Network tab. The response was served from your interceptor's `Map` cache. If you wait for the `max-age` duration to pass and trigger it again, a new network request should be made.