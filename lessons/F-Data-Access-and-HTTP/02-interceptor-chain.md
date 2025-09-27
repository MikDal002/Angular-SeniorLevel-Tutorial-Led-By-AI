# Lesson 2: Interceptor Chain

Angular's `HttpClient` allows you to register multiple `HttpInterceptor` instances. These interceptors form a **chain of responsibility**. Each interceptor can process an HTTP request on its way out and the response on its way back in.

The order in which you provide these interceptors is critical, as it dictates the flow of logic. This lesson covers how to build a robust interceptor chain to handle common cross-cutting concerns like authentication, caching, error handling, and retries.

- **Resource:** [Official Angular Documentation on Interceptor Order](https://angular.io/guide/http-interceptors#interceptor-order)

## How the Interceptor Chain Works

When you provide multiple interceptors, Angular applies them in the order they are listed in the `providers` array.

If you provide them in this order:
1.  `AuthInterceptor`
2.  `CachingInterceptor`
3.  `ErrorInterceptor`

The flow will be:
-   **Request Out:** `AuthInterceptor` -> `CachingInterceptor` -> `ErrorInterceptor` -> Server
-   **Response In:** Server -> `ErrorInterceptor` -> `CachingInterceptor` -> `AuthInterceptor`

The response flows back through the chain in the reverse order of the request.

## Building a Coherent Interceptor Chain

Let's design a chain to handle authentication, ETag-based caching, a retry strategy, and global error handling. The order is very important for these to work together correctly.

A logical order would be:
1.  **Auth Interceptor:** Adds the `Authorization` header. This should happen early so that the token is present for subsequent interceptors and the final request.
2.  **ETag/Caching Interceptor:** Handles caching logic. It needs to see the auth header. It might stop the request from going to the server if a cached value is available.
3.  **Retry Interceptor:** Wraps the final call to the server with a retry strategy. This should be one of the last interceptors so that it can retry the *entire* modified request.
4.  **Error Logging Interceptor:** Catches any errors that occur and logs them. This should be placed late in the chain to catch errors from any of the preceding interceptors or the server itself.

### Providing the Interceptors in Order (Standalone API)

In a modern standalone application, you provide interceptors using `withInterceptors`. The order of the array determines the order of execution.

```typescript
// app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { authInterceptor } from './interceptors/auth.interceptor';
import { etagInterceptor } from './interceptors/etag.interceptor';
import { retryInterceptor } from './interceptors/retry.interceptor';
import { errorLoggingInterceptor } from './interceptors/error-logging.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(withInterceptors([
      // Order matters!
      authInterceptor,
      etagInterceptor,
      retryInterceptor,
      errorLoggingInterceptor
    ])),
  ],
};
```

## Example Interceptors

Here are simplified examples of what each interceptor in our chain might look like.

### 1. `auth.interceptor.ts`

Adds the authentication token. It should be first so the token is available for all subsequent operations.

```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authToken = 'YOUR_TOKEN'; // Get from a service
  const authReq = req.clone({
    setHeaders: { Authorization: `Bearer ${authToken}` }
  });
  return next(authReq);
};
```

### 2. `etag.interceptor.ts` (Conceptual)

Handles `If-None-Match` headers for ETag-based caching. This needs to run after the auth interceptor.

```typescript
export const etagInterceptor: HttpInterceptorFn = (req, next) => {
  const cachedEtag = getEtagForUrl(req.url); // Logic to get a cached ETag
  if (cachedEtag) {
    const etagReq = req.clone({
      setHeaders: { 'If-None-Match': cachedEtag }
    });
    return next(etagReq);
  }
  return next(req);
};
```

### 3. `retry.interceptor.ts`

Applies a retry strategy. This should be late in the chain to retry the fully formed request.

```typescript
import { retry } from 'rxjs/operators';
import { genericRetryStrategy } from './retry.strategy'; // From a previous lesson

export const retryInterceptor: HttpInterceptorFn = (req, next) => {
  // Only apply retry to GET requests
  if (req.method === 'GET') {
    return next(req).pipe(retry(genericRetryStrategy()));
  }
  return next(req);
};
```

### 4. `error-logging.interceptor.ts`

Catches and logs errors. Placing it last ensures it can catch errors from the server *and* any errors thrown by the other interceptors.

```typescript
import { catchError, throwError } from 'rxjs';

export const errorLoggingInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      console.error('HTTP Error:', error.status, error.message);
      // Here you would inject and use a real logging service
      // loggingService.logHttpError(error);
      return throwError(() => error); // Re-throw the error
    })
  );
};
```

---

## ✅ Verifiable Outcome

You can verify that your interceptor chain is working in the correct order by adding `console.log` statements to each interceptor and observing the output.

1.  **Implement the Interceptors:**
    -   Create the four interceptors as described in the lesson: `auth`, `etag`, `retry`, and `errorLogging`.
    -   In each interceptor, add a log statement at the beginning of the `intercept` function (e.g., `console.log('Auth Interceptor - Request Out')`).
    -   In the `pipe()` block for the response, add another log (e.g., `console.log('Auth Interceptor - Response In')`).
    -   Provide them in the correct order in your `app.config.ts`.

2.  **Trigger an HTTP Call:**
    -   Create a component that makes a simple `HttpClient.get()` call to a public API.
    -   Run the application and trigger the API call.

3.  **Verify the Order:**
    -   Open the browser's developer console.
    -   **Expected Result:** You should see the "Request Out" logs appear in the exact order you provided the interceptors:
        ```
        Auth Interceptor - Request Out
        ETag Interceptor - Request Out
        Retry Interceptor - Request Out
        Error Logging Interceptor - Request Out
        ```
    -   After the network request completes, you should see the "Response In" logs appear in the **reverse** order:
        ```
        Error Logging Interceptor - Response In
        Retry Interceptor - Response In
        ETag Interceptor - Response In
        Auth Interceptor - Response In
        ```
    -   This confirms that you have correctly configured the chain and understand how requests and responses flow through it.