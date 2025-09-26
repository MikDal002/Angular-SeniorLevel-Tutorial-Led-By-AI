# Lesson 2: Token Refresh and Silent Renew

Access tokens are, by design, short-lived (e.g., 15-60 minutes). This enhances security. However, forcing the user to log in again every hour is a terrible user experience. The solution is the **Refresh Token**.

A refresh token is a long-lived credential that the client can use to get a new access token without requiring the user to log in again. This process is called "silent renew" or "token refresh."

A major challenge with this flow in an SPA is handling race conditions. If multiple, parallel API calls fail with a `401 Unauthorized` error (because the access token expired), they might all try to trigger a token refresh at the same time. This can lead to invalid refresh attempts and can log the user out unnecessarily.

The solution is a **"single-flight" refresh pattern**, where only the first failed request triggers the refresh, and all subsequent requests wait for it to complete before being retried.

- **Resource:** [Refreshing a Token using Code Flow](https://manfredsteyer.github.io/angular-oauth2-oidc/docs/additional-documentation/token-refresh.html)
- **Resource:** [Discussion on Refresh Token Race Conditions](https://www.reddit.com/r/reactjs/comments/1n94ajl/how_do_you_all_handle_refresh_token_race/)

## The Single-Flight Refresh Pattern

We can implement this pattern using an `HttpInterceptor` and some clever RxJS in an `AuthService`.

### 1. The `AuthService`

The `AuthService` will manage the refresh logic. It needs to keep track of whether a refresh is currently in progress.

```typescript
// auth.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { switchMap, catchError, filter, take, tap, shareReplay } from 'rxjs/operators';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private refreshTokenInProgress = false;
  // A Subject that will emit the new access token when the refresh is complete.
  private refreshTokenSubject = new BehaviorSubject<string | null>(null);
  // A shared, multicasted stream for the refresh token API call.
  private refreshToken$: Observable<any>;

  constructor(private http: HttpClient) {}

  // This is the main entry point for the interceptor.
  handle401Error(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    if (!this.refreshTokenInProgress) {
      // --- Start of the "single-flight" ---
      this.refreshTokenInProgress = true;
      this.refreshTokenSubject.next(null);

      // We need to get the refresh token from storage
      const refreshToken = this.getRefreshToken(); // Implement this
      if (!refreshToken) {
        this.refreshTokenInProgress = false;
        // Logout user if no refresh token is available
        return throwError(() => new Error('No refresh token'));
      }

      this.refreshToken$ = this.http.post('/api/auth/refresh', { refreshToken }).pipe(
        tap((tokens: any) => {
          this.refreshTokenInProgress = false;
          this.storeNewTokens(tokens); // Implement this
          this.refreshTokenSubject.next(tokens.accessToken);
        }),
        catchError(err => {
          this.refreshTokenInProgress = false;
          // Logout user if refresh fails
          return throwError(() => err);
        }),
        // Ensure the stream is shared and replays the result
        shareReplay(1)
      );

      return this.refreshToken$.pipe(
        switchMap(() => {
          // Retry the original request with the new token
          return next.handle(this.addTokenToRequest(request));
        })
      );
    } else {
      // --- A refresh is already in progress, wait for it to complete ---
      return this.refreshTokenSubject.pipe(
        filter(token => token != null),
        take(1),
        switchMap(() => {
          // Retry the original request with the new token
          return next.handle(this.addTokenToRequest(request));
        })
      );
    }
  }

  private addTokenToRequest(request: HttpRequest<any>): HttpRequest<any> {
    const token = this.getAccessToken(); // Implement this
    if (!token) { return request; }
    return request.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
  }

  // ... other methods like getRefreshToken, storeNewTokens, getAccessToken ...
}
```

### 2. The Auth Interceptor

The interceptor's job is now much simpler. It just needs to catch `401` errors and delegate the handling to the `AuthService`.

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
    // First, add the current access token to the request
    const authorizedRequest = this.addTokenToRequest(request);

    return next.handle(authorizedRequest).pipe(
      catchError((error: HttpErrorResponse) => {
        // If we get a 401, and it's not from the refresh token endpoint itself
        if (error.status === 401 && !request.url.includes('/auth/refresh')) {
          return this.authService.handle401Error(authorizedRequest, next);
        }
        // For all other errors, just re-throw
        return throwError(() => error);
      })
    );
  }

  private addTokenToRequest(request: HttpRequest<any>): HttpRequest<any> {
    const token = this.authService.getAccessToken();
    if (!token) { return request; }
    return request.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
  }
}
```

### How It Works

1.  The interceptor adds the current access token to all outgoing requests.
2.  An API call fails with a `401`. The `catchError` in the interceptor triggers.
3.  It calls `authService.handle401Error()`.
4.  **First Request:** `refreshTokenInProgress` is `false`. It gets set to `true`. The service makes the call to `/api/auth/refresh`. The result of this call is piped into a `shareReplay` observable (`refreshToken$`).
5.  **Concurrent Requests:** While the first refresh is in flight, other API calls also fail with a `401`. They also call `handle401Error()`. This time, `refreshTokenInProgress` is `true`. These requests don't trigger a new refresh. Instead, they subscribe to `refreshTokenSubject`.
6.  **Refresh Completes:** The `/api/auth/refresh` call returns new tokens. The `tap` operator in the `AuthService` stores them and emits the new access token via `refreshTokenSubject.next()`. The `refreshTokenInProgress` flag is set back to `false`.
7.  All the waiting requests (which were subscribed to `refreshTokenSubject`) now receive the new token, get retried with the new token, and proceed as normal.

This pattern ensures that no matter how many API calls fail simultaneously, the token refresh operation is only ever performed once, preventing race conditions and creating a seamless, resilient user experience.