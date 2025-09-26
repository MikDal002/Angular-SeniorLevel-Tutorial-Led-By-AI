# Lesson 6: Session Persistence and Logout Flows

Once a user is logged in, there are two critical parts of the session lifecycle to manage: how to keep them logged in across page refreshes, and how to properly log them out.

## 1. Token Storage and Session Persistence

A major question in SPA security is where to store the JWTs (access token, refresh token, id token) received from the Authorization Server.

### The Storage Options and Their Trade-offs

-   **`localStorage`**:
    -   **Pros:** Persistent across tabs and browser restarts.
    -   **Cons:** **Most vulnerable to XSS.** If an attacker can inject a script onto your page, they can read everything in `localStorage` and steal the tokens.
-   **`sessionStorage`**:
    -   **Pros:** Scoped to a single browser tab and cleared when the tab is closed.
    -   **Cons:** Still vulnerable to XSS within that tab.
-   **In-Memory (e.g., in an `AuthService` property)**:
    -   **Pros:** **Most secure.** Cannot be read by a cross-site script.
    -   **Cons:** State is lost on a page refresh.

**Best Practice:** For the highest security, store tokens **in-memory**. The "lost on refresh" problem is solved not by persisting the token in an insecure place, but by performing a **silent renew** when the application loads.

- **Resource:** [Best Practices for Storing Access Tokens in Angular](https://medium.com/@sehban.alam/best-practices-for-storing-access-tokens-in-angular-0d835c14e72c)

### Implementing Silent Renew on Startup

If we store tokens in memory, how does the user stay logged in after hitting F5? We use the long-lived session at the Authorization Server.

The pattern works like this:
1.  When the Angular application first loads, the `AuthService` checks if it has an access token in memory.
2.  If not, it checks if a session exists with the Authorization Server. Many OIDC client libraries (`angular-oauth2-oidc`, `auth0-spa-js`, etc.) provide a `trySilentLogin()` or `checkSession()` method for this.
3.  This method uses a hidden `iframe` to silently perform an OIDC flow with the Authorization Server.
4.  Since the user already has a valid session cookie with the Authorization Server, the server immediately returns a new set of tokens without requiring any user interaction.
5.  The `AuthService` loads these new tokens into memory, and the user's session is restored.

This gives you the security of in-memory storage with the user experience of a persistent session.

## 2. Implementing a Proper Logout Flow

A logout is more than just deleting tokens from the client. A full OIDC logout involves two steps:
1.  Clearing the local application state.
2.  Redirecting the user to the Authorization Server's **end session endpoint**.

This second step is crucial for "single sign-out." It ensures the user's session at the central identity provider is terminated, which can then trigger logouts from other applications that might be using the same session.

- **Resource:** [OIDC End Session Endpoint](https://docs.duendesoftware.com/identityserver/reference/endpoints/end-session/)

### The Logout Implementation

Let's implement a `logout()` method in our `AuthService`.

```typescript
// auth.service.ts
import { Injectable } from '@angular/core';
import { Store } from '@ngrx/store';
import { AuthActions } from './state/auth.actions'; // Assuming NgRx for state

@Injectable({ providedIn: 'root' })
export class AuthService {
  // Assume these are discovered or configured
  private endSessionEndpoint = 'https://my-auth-server.com/connect/endsession';
  private postLogoutRedirectUri = 'http://localhost:4200/logged-out';

  constructor(private store: Store) {}

  public logout(): void {
    // 1. Clear local state
    // This could be dispatching an NgRx action, clearing a BehaviorSubject, etc.
    this.store.dispatch(AuthActions.logout());

    // You would also clear any in-memory token variables here.
    this.accessToken = null;
    this.refreshToken = null;

    // 2. Construct the redirect URL
    // We need to tell the auth server where to send the user back after logout.
    const redirectUrl = `${this.endSessionEndpoint}?post_logout_redirect_uri=${encodeURIComponent(this.postLogoutRedirectUri)}`;

    // 3. Perform the redirect
    window.location.href = redirectUrl;
  }
}
```

### The Flow

1.  A user clicks a "Logout" button in the application.
2.  The component calls `authService.logout()`.
3.  The service first clears all local session information. This is important so that if the user hits the "back" button, they don't appear to be logged in.
4.  The service then redirects the browser to the Authorization Server's `end_session_endpoint`.
5.  The Authorization Server clears its session cookie for our application.
6.  The Authorization Server then redirects the user back to the `post_logout_redirect_uri` we provided, which could be a simple "You have been logged out" page in our Angular app.

This ensures a complete and secure logout, terminating the session at both the client and the central identity provider.