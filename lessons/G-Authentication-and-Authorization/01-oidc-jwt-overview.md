# Lesson 1: OIDC/JWT Overview with ASP.NET Core Concepts

Modern web applications have moved away from traditional session-based authentication (where the server stores login state). The standard for modern, decoupled applications (like an Angular SPA talking to an ASP.NET Core Web API) is **token-based authentication**, built on the standards of **OAuth 2.0**, **OpenID Connect (OIDC)**, and **JSON Web Tokens (JWT)**.

This lesson provides a high-level overview of how these pieces fit together.

## The Players in the Game

1.  **Resource Owner:** The **user** who owns the data.
2.  **Client:** The **Angular SPA**. This is a "public client" because it runs in the browser and cannot securely store a secret.
3.  **Resource Server:** The **ASP.NET Core Web API** that protects the user's data.
4.  **Authorization Server (AS):** A dedicated, trusted server responsible for authenticating the user and issuing tokens. Examples include Auth0, Okta, Duende IdentityServer, or Azure AD B2C.

## The Big Picture: How Authentication Works

The core idea is to **delegate authentication**. The Angular app *never* sees the user's password. Instead, it redirects the user to the Authorization Server to log in.

### The Flow (Authorization Code Flow with PKCE)

This is the current industry best-practice flow for SPAs.

1.  **Login Initiated:** The user clicks "Login" in the Angular app.
2.  **Redirect to Authorization Server:** The Angular app redirects the user's browser to the Authorization Server's login page. It includes some important query parameters:
    -   `client_id`: Identifies our Angular app.
    -   `redirect_uri`: Tells the AS where to send the user back after login.
    -   `scope`: Specifies what we're asking for (e.g., `openid profile email api1`). `openid` is the key that signifies an OIDC request.
    -   `code_challenge`: A temporary, secret-like value created by the Angular app for this specific login attempt.
3.  **User Authenticates:** The user enters their credentials directly on the Authorization Server's trusted page.
4.  **Consent:** The user might be asked to consent to allowing your application to access their profile information.
5.  **Redirect Back with Authorization Code:** The AS redirects the user back to the Angular app's `redirect_uri`. Included in the URL is a temporary, one-time-use **authorization code**.
6.  **Exchange Code for Tokens:** The Angular app's code, running in the browser, takes this authorization code and makes a direct, behind-the-scenes `POST` request to the AS's token endpoint. It includes the `code_challenge` from step 2 to prove it's the same client that started the process.
7.  **Tokens Issued:** The AS validates the code and `code_challenge`, and if everything is correct, it returns a set of tokens.

- **Resource:** [Securely Using the OIDC Authorization Code Flow for SPAs](https://www.pingidentity.com/en/resources/blog/post/securely-using-oidc-authorization-code-flow-public-client-single-page-apps.html)

## The Tokens: JWTs

The tokens issued by the Authorization Server are typically **JSON Web Tokens (JWTs)**. A JWT is a compact, self-contained string that contains JSON data. It's cryptographically signed by the Authorization Server, so the Resource Server (our API) can trust its contents.

There are two main types of tokens:

### 1. `id_token` (The "Who")

-   **Purpose:** Proves that the user has been authenticated.
-   **Audience:** Meant for the **Client** (the Angular app).
-   **Content:** Contains information about the user and the authentication event (e.g., user's unique ID (`sub`), who issued the token (`iss`), when it expires (`exp`)).
-   **What the Angular app does with it:** The app can decode this token to get user profile information to display in the UI (e.g., "Welcome, Jane Doe"). It should validate the signature to ensure it's legitimate.

### 2. `access_token` (The "What")

-   **Purpose:** Grants access to a protected resource.
-   **Audience:** Meant for the **Resource Server** (the ASP.NET Core API).
-   **Content:** Contains information about the permissions (scopes) the client has been granted (e.g., `scope: "read:products"`, `scope: "write:orders"`).
-   **What the Angular app does with it:** The app treats this token as an opaque string. It attaches it to the `Authorization` header of every request it makes to the protected API.
    ```
    Authorization: Bearer <the_access_token>
    ```

## The API's Role (ASP.NET Core)

When the ASP.NET Core API receives a request with an `Authorization: Bearer ...` header:
1.  It inspects the JWT access token.
2.  It validates the token's signature to ensure it was issued by the trusted Authorization Server and hasn't been tampered with.
3.  It checks the token's expiration time (`exp` claim).
4.  It checks the token's audience (`aud` claim) to ensure the token was intended for this specific API.
5.  It inspects the token's scopes to determine if the client is authorized to perform the requested action.

If all checks pass, the API processes the request. If not, it returns a `401 Unauthorized` or `403 Forbidden` error.

---

## ✅ Verifiable Outcome

You can verify your understanding of this flow by using a public OIDC playground.

1.  **Use an OIDC Debugger:**
    -   Go to a public OIDC debugger tool, like the one provided by [Auth0](https://oidcdebugger.com/) or [Okta](https://oidcdebugger.com/). These tools act as a sample client application.

2.  **Configure and Authenticate:**
    -   The debugger will require an "Authorize URI" and a "Client ID" from an Authorization Server. You can often use the pre-filled sample values they provide.
    -   Click the "Send Request" button.
    -   You will be redirected to the Authorization Server's login page. Log in with the provided sample credentials (or your own account).
    -   You may be asked to grant consent for the "application" (the debugger) to access your information.

3.  **Inspect the Tokens:**
    -   After you log in and grant consent, you will be redirected back to the debugger tool.
    -   **Expected Result:** The tool will display the `id_token` and `access_token` it received from the Authorization Server.
    -   Copy the `id_token` string and paste it into a JWT debugger like [jwt.io](https://jwt.io/). You will be able to see the decoded JSON payload, which contains claims like `sub` (subject/user ID), `iss` (issuer), and `exp` (expiration time), confirming your understanding of the token's contents.