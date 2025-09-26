# Lesson 4: Auth Interceptor and Race-Proof Queueing

The `HttpInterceptor` is the heart of your application's authentication system. Its primary jobs are to attach the current access token to outgoing requests and, critically, to handle what happens when that token expires.

As discussed in the "Token Refresh" lesson, a major challenge is the race condition that occurs when multiple, parallel API calls fail at the same time with a `401 Unauthorized` status. This lesson provides a focused review of the **single-flight, race-proof queueing** pattern used to solve this problem.

## The Problem: The Refresh Token Race Condition

1.  An access token expires.
2.  The user performs an action that triggers three different API calls simultaneously (e.g., fetching user data, notifications, and settings).
3.  All three requests are sent with the expired token.
4.  All three requests fail with a `401 Unauthorized` error.
5.  **Without a race-proof pattern**, all three failed requests would *independently* try to use the refresh token to get a new access token.
6.  The first refresh attempt succeeds. The second and third attempts will likely fail because many authorization servers invalidate the refresh token upon use.
7.  The result is a broken user session and a likely forced logout.

## The Solution: Single-Flight Queueing

The solution is to ensure that only the *first* `401` error triggers the refresh mechanism. All subsequent requests that fail while the refresh is in progress are "queued" and wait for the refresh to complete before being retried.

This pattern is implemented by splitting the logic between the `HttpInterceptor` and an `AuthService`.

### The Role of the `AuthInterceptor`

The interceptor is the entry point. It's simple and has two responsibilities:
1.  Add the current access token to every outgoing request.
2.  If a request fails with a `401`, delegate the complex handling logic to the `AuthService`.

```typescript
// auth.interceptor.ts
import { Injectable } from '@angular/core';
import {
  HttpRequest, HttpHandler, HttpEvent, HttpInterceptor, HttpErrorResponse
} from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { AuthService } from './auth.service';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private authService: AuthService) {}

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // Add the token from the AuthService
    const authorizedRequest = this.addTokenToRequest(request);

    return next.handle(authorizedRequest).pipe(
      catchError((error: HttpErrorResponse) => {
        // If it's a 401, delegate to the AuthService.
        // The service will handle the refresh and retry logic.
        if (error.status === 401) {
          return this.authService.handle401Error(authorizedRequest, next);
        }
        // For other errors, just re-throw.
        return throwError(() => error);
      })
    );
  }
  // ... addTokenToRequest method
}
```

### The Role of the `AuthService`

The `AuthService` contains the core queueing logic. It uses a flag (`refreshTokenInProgress`) and a `BehaviorSubject` to manage the state of the refresh operation.

```typescript
// auth.service.ts
@Injectable({ providedIn: 'root' })
export class AuthService {
  private refreshTokenInProgress = false;
  private refreshTokenSubject = new BehaviorSubject<string | null>(null);

  handle401Error(request: HttpRequest<any>, next: HttpHandler) {
    if (!this.refreshTokenInProgress) {
      // --- This is the first request. Start the refresh. ---
      this.refreshTokenInProgress = true;
      this.refreshTokenSubject.next(null); // Signal that a refresh is happening

      return this.http.post('/api/auth/refresh', { /* ... */ }).pipe(
        tap((tokens: any) => {
          // Refresh succeeded.
          this.refreshTokenInProgress = false;
          this.storeNewTokens(tokens);
          this.refreshTokenSubject.next(tokens.accessToken); // Broadcast the new token
        }),
        catchError(err => {
          // Refresh failed.
          this.refreshTokenInProgress = false;
          // this.logout(); // Logout the user
          return throwError(() => err);
        }),
        // Retry the original request after the refresh completes.
        switchMap(() => next.handle(this.addTokenToRequest(request)))
      );

    } else {
      // --- A refresh is already in flight. Queue this request. ---
      return this.refreshTokenSubject.pipe(
        filter(token => token != null), // Wait until the subject emits a new token
        take(1), // Take the first new token
        // Retry the original request
        switchMap(() => next.handle(this.addTokenToRequest(request)))
      );
    }
  }
  // ... other methods
}
```

### Visualizing the Flow

1.  **Request 1 (fails with 401):** Enters `handle401Error`. `refreshTokenInProgress` is `false`. It flips the flag to `true` and initiates the call to `/api/auth/refresh`. It returns an observable that will eventually retry the original request.
2.  **Request 2 (fails with 401):** Enters `handle401Error`. `refreshTokenInProgress` is now `true`. It skips the refresh logic and instead subscribes to `refreshTokenSubject`, waiting for a new token.
3.  **Request 3 (fails with 401):** Does the same as Request 2.
4.  **Refresh Completes:** The `/api/auth/refresh` call returns. The new tokens are stored, and `refreshTokenSubject` emits the new access token.
5.  **Queue is Released:** Request 2 and Request 3, which were waiting on `refreshTokenSubject`, now receive the new token. Their `switchMap` operators execute, and they are retried with the valid token. Request 1's observable chain also proceeds to retry itself.

This pattern elegantly solves the race condition by creating a temporary, asynchronous "lock" (`refreshTokenInProgress`) and a queue (`refreshTokenSubject`), ensuring a smooth and seamless experience for the user even when their access token expires.