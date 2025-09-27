# Capstone Project: E-Commerce Checkout SPA

This capstone project is the culmination of all the concepts covered in this course. The goal is to build a small but feature-rich and production-quality "book e-commerce checkout" single-page application.

This project will not be a step-by-step tutorial, but rather a set of requirements. You should use the knowledge from the previous modules to design and build the solution.

## Core Requirements

You will deliver a fully tested, performant, and secure cart/checkout flow with CI quality gates passing.

### 1. Feature-Sliced Architecture (Module B)
-   Structure your application using the Feature-Sliced Design principles.
-   You should have clear `app`, `pages`, `features`, `entities`, and `shared` layers.
-   **Entities:** `Book`, `CartItem`, `Order`, `User`.
-   **Features:** `addToCart`, `updateCartQuantity`, `removeFromCart`, `submitOrder`.
-   **Pages:** `ProductListPage`, `ProductDetailPage`, `CartPage`, `CheckoutPage`, `OrderConfirmationPage`.

### 2. Authentication and Authorization (Module G)
-   Implement a full OIDC authentication flow (you can use a mock auth server or a real one like Auth0/Okta).
-   Protect the `/checkout` and `/account` routes so they are only accessible to logged-in users (`canMatch` guards).
-   Use an `HttpInterceptor` to attach the auth token to API requests.
-   Implement a race-proof token refresh mechanism.
-   Show/hide "Login" and "Logout" buttons based on the user's auth state.

### 3. State Management (Module E)
-   Use the **global NgRx Store** for managing the shopping cart (`CartItem[]`) and user session state.
-   Use **NgRx Entity** to manage the cart items for performant updates.
-   Use **NgRx Component Store** for any feature-local state (e.g., the state of the checkout form).
-   Implement an **optimistic update** when a user updates the quantity of an item in the cart. If the API call fails, roll back the change and notify the user.

### 4. Data Access and HTTP (Module F)
-   Use a shared, caching data stream (`shareReplay`) for the list of books, with a manual refresh trigger.
-   Implement a `412 Precondition Failed` check for the final "Submit Order" action to prevent double-submits or submitting an order with out-of-date pricing.
-   All data access should be done through abstract services (ports) with concrete implementations (adapters), as covered in Module B.

### 5. Forms and Validation (Module I)
-   Build the checkout form using **strongly-typed reactive forms**.
-   Include an **async validator** on a "Coupon Code" field that checks the API for the code's validity. This validator must be debounced and handle cancellation.
-   Implement **accessible error patterns**, ensuring error messages are linked to their inputs (`aria-describedby`) and that focus is managed correctly on submission.

### 6. Components and Performance (Modules C & H)
-   Use the `OnPush` change detection strategy for all components.
-   Use **signals** for local component state and derived values (`computed`).
-   Use `toSignal` and `toObservable` for clean RxJS interop.
-   The main product list page should use the **CDK Virtual Scroll** component to efficiently render a large list of books.
-   The "related products" section on the product details page should be in a **`@defer` block** that loads on viewport entry.

### 7. Quality Gates and CI (Modules A & J)
-   Set up **Husky** to lint commit messages (`commitlint`).
-   Set up **lint-staged** to run ESLint and Prettier on pre-commit.
-   Create a **GitHub Actions** workflow that runs on every pull request and does the following:
    -   Installs dependencies (with caching).
    -   Runs the linter (`ng lint`).
    -   Runs all unit and integration tests (`ng test`).
    -   Runs all E2E tests (`npx playwright test`).
-   Configure **performance budgets** in `angular.json` to fail the build if the initial bundle size exceeds a reasonable limit (e.g., 500kb).

### 8. Testing (Module J)
-   Write **user-centric component tests** using Angular Testing Library.
-   Write **unit tests** for your NgRx reducers, selectors, and effects (using marble testing for time-based logic).
-   Write an **integration test** for the "add to cart" flow, mocking the `HttpClient` but using the real NgRx store and effects.
-   Write **Playwright E2E tests** for the full checkout flow, mocking the authentication state and API responses.
-   Use **Storybook** to document your shared UI components (e.g., buttons, inputs) and write interaction tests for them using the `play` function.

### 9. Security and Operations (Module K)
-   Configure a strict **Content Security Policy (CSP)** for the application via server headers.
-   Integrate a third-party logging service (like Sentry) into a custom `ErrorHandler` to capture and report all uncaught exceptions.
-   Integrate a RUM service to monitor **Core Web Vitals** in production.

This capstone project will challenge you to apply all the patterns and best practices from this course to build an application that is not just functional, but also scalable, performant, maintainable, and secure. Good luck!

## Final Verification Checklist

Before considering the project complete, ensure you can check off all of the following items. This checklist summarizes the core quality and feature requirements.

- **CI/CD Quality Gates:**
    - [ ] All GitHub Actions checks are consistently passing on your main branch.
    - [ ] This includes `ng lint`, `ng test`, and `npx playwright test`.
    - [ ] The production build does not fail the performance budget checks in `angular.json`.

- **Authentication and Authorization:**
    - [ ] The `/checkout` route is successfully protected by a `canMatch` guard, redirecting unauthenticated users.
    - [ ] The UI correctly shows "Login" or "Logout" based on authentication status.
    - [ ] The `HttpInterceptor` correctly attaches the Bearer token to authenticated API requests.

- **Core Application Flow (Manual Check):**
    - [ ] **Product List:** The main product list page renders correctly and uses virtual scrolling for performance.
    - [ ] **Deferred Loading:** The "related products" section on a product detail page loads only when scrolled into view.
    - [ ] **Cart Management:** Items can be added to the cart, quantities can be updated (with optimistic UI), and items can be removed. All actions are reflected in the NgRx store.
    - [ ] **Checkout Form:** The form is built with strongly-typed reactive forms and includes all necessary validators, including the debounced async validator for the coupon code.
    - [ ] **Order Submission:** A valid order can be successfully submitted, and the user is redirected to a confirmation page.
    - [ ] **Error Handling:** API errors (like the 412 Precondition Failed) are gracefully handled, and the user is notified.

- **Testing and Documentation:**
    - [ ] Unit tests for NgRx state logic (reducers, selectors, effects) are complete and passing.
    - [ ] User-centric component tests cover critical UI components.
    - [ ] E2E tests cover the full "happy path" of a user adding an item to the cart and completing a checkout.
    - [ ] Shared UI components are documented with Storybook and include interaction tests.

- **Security & Operations:**
    - [ ] A strict Content Security Policy (CSP) is delivered via server headers and can be verified using browser dev tools.
    - [ ] Triggering a test exception in the application results in a report being sent to your configured logging service (e.g., Sentry).