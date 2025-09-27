# Lesson 1: Zoneless Change Detection (Optional)

This is an advanced and still-experimental feature in Angular.

For its entire history, Angular has relied on a library called **Zone.js** to know *when* to run change detection. Zone.js "monkey-patches" browser APIs (like `setTimeout`, `addEventListener`, `Promise.then`), which allows Angular to automatically trigger change detection whenever any asynchronous event occurs in the application.

This is convenient, but it has downsides:
-   **Bundle Size:** Zone.js adds a non-trivial amount to your application's bundle size.
-   **"Magic":** It can feel like magic. Sometimes change detection runs more often than you expect, leading to performance issues.
-   **Over-rendering:** Any async event can trigger a check of the entire component tree (unless you use `OnPush`), which can be inefficient.

**Zoneless** change detection is a new, experimental mode in Angular that allows you to remove Zone.js entirely.

- **Resource:** [Official Angular Zoneless Guide](https://angular.dev/guide/zoneless)
- **Resource:** [Zoneless Angular by Angular Experts](https://angularexperts.io/blog/zoneless-angular)
- **Resource:** [Angular `ChangeDetectorRef` API Docs](https://angular.dev/api/core/ChangeDetectorRef)

## How Zoneless Works

In a zoneless application, Angular no longer automatically knows when to run change detection. The "magic" is gone. Instead, you must be **explicit** about telling Angular when the UI needs to be updated.

There are two primary ways to trigger change detection in a zoneless app:

1.  **Using Signals:** This is the preferred and modern way. When you use a signal in a component's template and that signal's value is updated, Angular knows precisely which component needs to be checked and will schedule an update. The signal-based component model is designed to work seamlessly with or without Zone.js.

2.  **Manual `markForCheck()`:** For cases where you aren't using signals (e.g., in a component that relies on plain observable-based state), you must manually inject `ChangeDetectorRef` and call `this.cdr.markForCheck()` to tell Angular that the component's state has changed and it needs to be re-rendered.

```typescript
// in a zoneless component not using signals
export class MyComponent {
  data: MyData;

  constructor(private cdr: ChangeDetectorRef) {}

  updateData(newData: MyData) {
    this.data = newData;
    // We MUST manually tell Angular to check this component.
    this.cdr.markForCheck();
  }
}
```

## How to Enable Zoneless

Enabling zoneless is done in your application's bootstrap configuration.

**1. Remove Zone.js Polyfill**
In your `polyfills.ts` (or `angular.json` polyfills array), remove the import for `zone.js`.

**2. Provide the Zoneless Config**
In your `main.ts`, use the `provideExperimentalZonelessChangeDetection` provider.

```typescript
// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { provideExperimentalZonelessChangeDetection } from '@angular/core';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';

bootstrapApplication(AppComponent, {
  providers: [
    // Provide the new zoneless strategy
    provideExperimentalZonelessChangeDetection(),
    // ... your other providers from app.config
  ]
}).catch((err) => console.error(err));
```

## Should You Go Zoneless?

**Benefits:**
-   **Smaller Bundle Size:** You remove the entire Zone.js library.
-   **More Control:** You have explicit, fine-grained control over when change detection runs.
-   **Performance:** Can lead to better performance by eliminating unnecessary change detection cycles, especially when combined with a signal-based architecture.

**Drawbacks / Considerations:**
-   **Experimental:** The API is still experimental and could change.
-   **Discipline Required:** You lose the "safety net" of automatic change detection. You *must* use signals or `markForCheck()` correctly, or your UI will not update.
-   **Third-Party Libraries:** Some third-party Angular libraries might still rely on Zone.js to function correctly. You need to verify that all your dependencies are compatible with a zoneless environment.

**Conclusion:**
Going zoneless is a significant architectural decision. It's a powerful option for performance-critical applications and for teams that are comfortable with the explicit nature of signal-based state management and change detection. As the Angular ecosystem continues to embrace signals, zoneless applications are likely to become more common.