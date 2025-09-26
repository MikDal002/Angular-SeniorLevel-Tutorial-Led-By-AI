# Lesson 3: NgRx Store Setup for Global Concerns

While Component Store is ideal for local state, some state is truly **global**. This is data that needs to be accessed and shared by many different, unrelated features across your application. The canonical examples are:

-   User authentication and session information (`User`, `token`, `isLoggedIn`)
-   Application-wide user settings or preferences (e.g., `theme`, `language`)

For this kind of global state, the traditional **NgRx Store** (`@ngrx/store`) is the appropriate tool. It provides a single, centralized, and predictable state container for the entire application.

- **Resource:** [State Management using NgRx store in Angular(for Standalone)](https://medium.com/angular-with-abhinav/state-management-using-ngrx-store-in-angular-for-standalone-1f5be1484f0e)
- **Resource:** [Angular Standalone - NgRx State Management Architecture](https://www.pkief.com/blog/angular-standalone-ngrx-state-management-architecture/)

## The NgRx Store Workflow

The global store follows a stricter, more structured pattern than Component Store:

1.  **Action:** A unique event is dispatched from a component or service (e.g., `[Auth API] Login Success`).
2.  **Reducer:** A pure function that hears the action. It takes the current state and the action's payload to produce a **new** state.
3.  **Store:** The single, global object that holds the state tree.
4.  **Selector:** A pure function for getting a slice of state from the store.
5.  **Effect:** A service that listens for actions, performs side effects (like API calls), and dispatches new actions in response (e.g., `[Auth API] Login Success` after a successful API call).

## Setting Up a Global Auth Store

Let's set up a simple global store to manage authentication state.

### 1. Install NgRx Packages

```bash
ng add @ngrx/store@latest
ng add @ngrx/effects@latest
ng add @ngrx/store-devtools@latest # For debugging
```

### 2. Define the State and Actions

Create files to define the shape of the state and the actions that can modify it.

**`auth.actions.ts`**
```typescript
import { createActionGroup, emptyProps, props } from '@ngrx/store';
import { User } from './auth.model';

export const AuthActions = createActionGroup({
  source: 'Auth API',
  events: {
    'Login Success': props<{ user: User; token: string }>(),
    'Login Failure': props<{ error: any }>(),
    'Logout': emptyProps(),
  },
});
```

**`auth.reducer.ts`**
```typescript
import { createReducer, on } from '@ngrx/store';
import { AuthActions } from './auth.actions';

export interface AuthState {
  user: User | null;
  token: string | null;
  isLoggedIn: boolean;
}

export const initialState: AuthState = {
  user: null,
  token: null,
  isLoggedIn: false,
};

export const authReducer = createReducer(
  initialState,
  on(AuthActions.loginSuccess, (state, { user, token }) => ({
    ...state,
    user,
    token,
    isLoggedIn: true,
  })),
  on(AuthActions.logout, () => initialState) // Reset to initial state on logout
);
```

### 3. Register the Store and Reducer

In a standalone application, you provide the store and reducers in your `app.config.ts`.

```typescript
// app.config.ts
import { ApplicationConfig, isDevMode } from '@angular/core';
import { provideStore } from '@ngrx/store';
import { provideStoreDevtools } from '@ngrx/store-devtools';
import { authReducer } from './state/auth/auth.reducer';

export const appConfig: ApplicationConfig = {
  providers: [
    provideStore({
      auth: authReducer, // 'auth' is the key for this slice of state
    }),
    provideStoreDevtools({
      maxAge: 25, // Retains last 25 states
      logOnly: !isDevMode(), // Restrict extension to log-only mode in production
    }),
    // ... other providers
  ],
};
```

### 4. Create Selectors

Create selectors to read the data from the store.

**`auth.selectors.ts`**
```typescript
import { createFeatureSelector, createSelector } from '@ngrx/store';
import { AuthState } from './auth.reducer';

// Select the 'auth' feature slice
export const selectAuthState = createFeatureSelector<AuthState>('auth');

export const selectIsLoggedIn = createSelector(
  selectAuthState,
  (state) => state.isLoggedIn
);

export const selectCurrentUser = createSelector(
  selectAuthState,
  (state) => state.user
);
```

### 5. Using the Store in a Component

Now, you can inject the `Store` service into any component, dispatch actions, and select state.

```typescript
// some.component.ts
import { Component, inject } from '@angular/core';
import { Store } from '@ngrx/store';
import { AuthActions } from './state/auth/auth.actions';
import { selectIsLoggedIn } from './state/auth/auth.selectors';

@Component({ /* ... */ })
export class SomeComponent {
  private store = inject(Store);
  isLoggedIn$ = this.store.select(selectIsLoggedIn);

  logout() {
    this.store.dispatch(AuthActions.logout());
  }
}
```

## When to Use Global Store vs. Component Store

| Concern              | Use Global Store (`@ngrx/store`)                                | Use Component Store (`@ngrx/component-store`)                               |
| -------------------- | --------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **Scope**            | Application-wide, shared across many unrelated features.        | Local to a single component or a small, self-contained feature.             |
| **Lifetime**         | Lives for the entire application session.                       | Created and destroyed along with its host component.                        |
| **Example State**    | User session, authentication token, user preferences, theme.    | Form state, UI flags (e.g., `isPanelOpen`), data for a specific feature page. |
| **Complexity**       | More boilerplate (actions, reducers, effects).                  | Less boilerplate, more concise.                                             |
| **Source of Truth**  | The single source of truth for global application state.        | A source of truth for its local domain.                                     |

By using both tools appropriately, you can build a clean, scalable state management architecture where global concerns are handled robustly and local state is managed efficiently without polluting the global namespace.