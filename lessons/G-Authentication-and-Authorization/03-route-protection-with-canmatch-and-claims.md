# Lesson 3: Route Protection with `canMatch` and Claims

A critical part of any application with authentication is protecting routes from unauthorized access. Angular's Router provides a powerful mechanism called **Route Guards** to handle this.

The modern and recommended approach for authentication-based route protection is the `canMatch` guard. This lesson covers how to use `canMatch` to protect routes based on whether a user is logged in and whether they have the required permissions (claims/roles).

- **Resource:** [Official `CanMatch` Documentation](https://angular.io/api/router/CanMatch)

## `canMatch` vs. `canActivate`

Angular has two primary guards for controlling access to a route:

-   **`canActivate`:** This guard runs *after* the router has already matched the URL to a route configuration. If it returns `false`, the router has to backtrack and find another route that matches. This is less efficient.
-   **`canMatch`:** This guard runs *before* the router fully commits to using a route. If `canMatch` returns `false`, the router simply pretends that route never existed and continues searching for a different match. This is more efficient and prevents lazy-loaded modules from being loaded unnecessarily for users who don't have access to them.

**Rule of thumb:** For protecting entire feature modules or routes based on authentication/authorization, `canMatch` is the preferred choice.

## 1. Creating an Authentication Guard

Let's create a simple guard that only allows access to a route if the user is authenticated. We'll assume an `AuthService` that can tell us if the user is logged in.

A guard is just a function that returns a `boolean`, `UrlTree`, `Observable<boolean | UrlTree>`, or `Promise<boolean | UrlTree>`.

```typescript
// auth.guard.ts
import { inject } from '@angular/core';
import { CanMatchFn, Router, Route, UrlSegment } from '@angular/router';
import { AuthService } from './auth.service';
import { map, take } from 'rxjs/operators';

export const authGuard: CanMatchFn = (route: Route, segments: UrlSegment[]) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  // Use an observable to check the login status
  return authService.isLoggedIn$.pipe(
    take(1), // We only need the current status
    map(isLoggedIn => {
      if (isLoggedIn) {
        return true; // Allow access to the route
      }
      // If not logged in, redirect to the login page
      return router.createUrlTree(['/login']);
    })
  );
};
```

### Applying the Guard

You apply the guard in your routing configuration using the `canMatch` property.

```typescript
// app.routes.ts
import { Routes } from '@angular/router';
import { authGuard } from './auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    component: LoginComponent
  },
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.routes').then(m => m.ADMIN_ROUTES),
    canMatch: [authGuard] // Protect the entire admin feature
  },
  // ... other routes
];
```
Now, if a user who is not logged in tries to navigate to any URL starting with `/admin`, the `authGuard` will run, return a `UrlTree` pointing to `/login`, and the router will redirect them. The code for the `admin` feature module will not even be downloaded.

## 2. Creating a Role-Based Guard (Claims)

Often, just being logged in isn't enough. You need to check if the user has a specific role or permission (often called a "claim" in JWTs) to access a certain area. We can create a more advanced, reusable guard for this.

This guard will be a factory function—a function that *returns* a `CanMatchFn` guard. This allows us to pass parameters to it, like the required role.

```typescript
// role.guard.ts
import { inject } from '@angular/core';
import { CanMatchFn, Router } from '@angular/router';
import { AuthService } from './auth.service';
import { map } from 'rxjs/operators';

// This is a factory function that returns our guard
export function roleGuard(requiredRole: string): CanMatchFn {
  return () => {
    const authService = inject(AuthService);
    const router = inject(Router);

    return authService.currentUser$.pipe(
      map(user => {
        // Check if the user exists and has the required role
        const hasRole = user?.roles?.includes(requiredRole) ?? false;

        if (hasRole) {
          return true; // Allow access
        }

        // If user doesn't have the role, redirect to a 'forbidden' page or home
        return router.createUrlTree(['/forbidden']);
      })
    );
  };
}
```

### Applying the Role Guard

Now you can use this factory in your routing configuration to protect routes that require specific roles.

```typescript
// admin.routes.ts
import { Routes } from '@angular/router';
import { roleGuard } from './role.guard';

export const ADMIN_ROUTES: Routes = [
  {
    path: 'dashboard',
    component: AdminDashboardComponent
  },
  {
    path: 'user-management',
    component: UserManagementComponent,
    canMatch: [roleGuard('SuperAdmin')] // Only SuperAdmins can access this
  },
  // ... other admin routes
];
```
In this example, all authenticated users can see the admin dashboard, but only users with the `SuperAdmin` role can access the user management page.

By using `canMatch` guards, you can create a secure, efficient, and highly flexible authorization system for your Angular application, ensuring that users can only access the routes and features they are permitted to see.