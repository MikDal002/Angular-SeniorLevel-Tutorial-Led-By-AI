# Lesson 1: Advanced Routing and Lazy Loading

As an Angular application grows, the initial JavaScript bundle size can become a major performance bottleneck. **Lazy loading** is the most effective strategy to combat this. It involves splitting your application into smaller chunks (feature modules) that are only loaded from the server when the user navigates to a route that requires them.

This lesson covers how to implement lazy loading and how to use **preloading strategies** to get the performance benefits of lazy loading without the latency penalty on navigation.

- **Resource:** [Route preloading strategies in Angular](https://web.dev/articles/route-preloading-in-angular)
- **Resource:** [Lazy Loading Angular Modules and Preloading Strategies](https://www.pluralsight.com/resources/blog/guides/lazy-loading-angular-modules-and-preloading-strategies)

## 1. Implementing Lazy Loading

Lazy loading is configured in your routing setup. Instead of using the `component` property, you use the `loadChildren` property. `loadChildren` takes a function that uses the dynamic `import()` syntax to load a file containing the routes for that feature.

**`app.routes.ts`**
```typescript
import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    pathMatch: 'full',
    redirectTo: 'home'
  },
  {
    path: 'home',
    component: HomeComponent // Eagerly loaded
  },
  {
    path: 'dashboard',
    // This tells the router to lazy load the dashboard routes
    // when the user navigates to '/dashboard'.
    loadChildren: () => import('./dashboard/dashboard.routes').then(m => m.DASHBOARD_ROUTES)
  },
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.routes').then(m => m.ADMIN_ROUTES)
  }
];
```
When the application first loads, the code for the `dashboard` and `admin` features is not included in the main bundle. Only when a user clicks a link to `/dashboard` will the browser fetch the JavaScript chunk for that feature.

## 2. The Downside of Lazy Loading: Navigation Latency

While lazy loading dramatically improves initial load time, it introduces a small delay when the user navigates to a lazy-loaded route for the first time. The browser has to fetch the new JavaScript chunk from the network before it can render the page.

This is where **preloading** comes in.

## 3. Preloading Strategies

Preloading is the process of loading lazy-loaded modules in the background *after* the initial application has been bootstrapped. This way, when the user eventually navigates to a lazy-loaded route, the code is likely already downloaded and ready to go, resulting in near-instant navigation.

Angular's router provides a `preloadingStrategy` option.

### `PreloadAllModules`

The simplest strategy is `PreloadAllModules`. This tells the router to preload *all* lazy-loaded modules in the background as soon as the main application is ready.

**`app.config.ts`**
```typescript
import { ApplicationConfig } from '@angular/core';
import { provideRouter, withPreloading, PreloadAllModules } from '@angular/router';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    // Enable the PreloadAllModules strategy
    provideRouter(routes, withPreloading(PreloadAllModules))
  ]
};
```
This is a great default choice for most applications.

### Custom Preloading Strategy

For more fine-grained control, you can create a custom preloading strategy. A common pattern is to add a `data` property to your route configuration to indicate that a specific route should be preloaded.

**1. Create the Custom Strategy**
A preloading strategy is a class that implements `PreloadingStrategy`. Its `preload` method receives the route and a `load` function. You return the `load` function if you want to preload the route, or `of(null)` if you don't.

```typescript
// selective-preload.strategy.ts
import { Injectable } from '@angular/core';
import { PreloadingStrategy, Route } from '@angular/router';
import { Observable, of } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class SelectivePreloadStrategy implements PreloadingStrategy {
  preload(route: Route, load: () => Observable<any>): Observable<any> {
    // Check for a `data.preload` flag in the route config
    if (route.data && route.data['preload']) {
      return load(); // Preload this route
    } else {
      return of(null); // Do not preload
    }
  }
}
```

**2. Configure the Routes**
Add `data: { preload: true }` to the routes you want to preload strategically.

```typescript
// app.routes.ts
export const routes: Routes = [
  // ...
  {
    path: 'dashboard',
    loadChildren: () => import('./dashboard/dashboard.routes').then(m => m.DASHBOARD_ROUTES),
    data: { preload: true } // We want to preload the dashboard
  },
  {
    path: 'admin', // The admin module is large and less-frequently used
    loadChildren: () => import('./admin/admin.routes').then(m => m.ADMIN_ROUTES)
    // No preload flag, so it will be truly lazy loaded on demand
  }
];
```

**3. Provide the Custom Strategy**
Finally, provide your custom strategy in `app.config.ts`.

```typescript
// app.config.ts
import { SelectivePreloadStrategy } from './selective-preload.strategy';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes, withPreloading(SelectivePreloadStrategy))
  ]
};
```
Now, only the `dashboard` module will be preloaded in the background, while the `admin` module remains fully lazy. This gives you the optimal balance between a small initial bundle and fast navigation to your most important features.

- **Resource:** [Beginner's Guide to Angular Preloading](https://zerotomastery.io/blog/beginners-guide-to-angular-preloading/)