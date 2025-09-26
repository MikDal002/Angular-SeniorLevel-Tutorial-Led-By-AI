# Lesson 5: Memory Leak Clinic (Subscriptions & Cleanup)

One of the most common and insidious problems in RxJS-heavy applications is the memory leak. A memory leak occurs when a component is destroyed, but subscriptions it created remain active in memory. This prevents the component and its dependencies from being garbage collected, leading to a slow, bloated, and eventually crashing application.

This lesson covers the modern, recommended way to handle subscription cleanup in Angular using `takeUntilDestroyed` and highlights common pitfalls.

## The Problem: Lingering Subscriptions

When you manually subscribe to an observable in a component, that subscription will live on forever unless you explicitly unsubscribe.

**The Classic Leak:**
```typescript
// a-classic-leak.component.ts
import { Component, OnInit } from '@angular/core';
import { interval } from 'rxjs';

@Component({ /* ... */ })
export class AClassicLeakComponent implements OnInit {
  ngOnInit() {
    // This subscription will NEVER die, even when the component is destroyed.
    // It will keep emitting values in the background, consuming memory.
    interval(1000).subscribe(val => {
      console.log('Leaky subscription is still running!', val);
    });
  }
}
```
Every time this component is created and destroyed (e.g., by navigating away and back), a new, permanent `interval` subscription is created, leading to a memory leak.

## The Old Way: Manual Cleanup with `ngOnDestroy`

For many years, the standard solution was to use a `Subject` that emits in `ngOnDestroy` and pipe it to the `takeUntil` operator.

```typescript
// the-old-way.component.ts
import { Component, OnInit, OnDestroy } from '@angular/core';
import { interval, Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({ /* ... */ })
export class TheOldWayComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  ngOnInit() {
    interval(1000).pipe(
      takeUntil(this.destroy$) // The stream will complete when destroy$ emits.
    ).subscribe(val => {
      console.log('Subscription is running...', val);
    });
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
```
This pattern works, but it's boilerplate-heavy and error-prone. Forgetting any part of it reintroduces the leak.

## The Modern Solution: `takeUntilDestroyed`

Angular now provides a much cleaner, built-in solution: the `takeUntilDestroyed` operator from `@angular/core/rxjs-interop`.

This operator automatically hooks into the component's lifecycle and completes the observable stream when the component is destroyed.

- **Action:** Use `takeUntilDestroyed` to simplify subscription management.

```typescript
// the-modern-way.component.ts
import { Component, OnInit, inject } from '@angular/core';
import { interval } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

@Component({ /* ... */ })
export class TheModernWayComponent implements OnInit {
  // Can be called in a constructor or as a property initializer.
  private destroyRef = inject(DestroyRef);

  ngOnInit() {
    interval(1000).pipe(
      // No more manual Subject or ngOnDestroy needed!
      takeUntilDestroyed(this.destroyRef)
    ).subscribe(val => {
      console.log('Clean subscription is running...', val);
    });
  }
}
```
*Note: If you call `takeUntilDestroyed` in a constructor, you don't need to pass the `DestroyRef` explicitly. It's automatically picked up from the injection context.*

- **Resource:** [Official `takeUntilDestroyed` Documentation](https://angular.io/guide/rxjs-interop#unsubscribing-with-takeuntildestroyed)

## The Higher-Order Operator Pitfall

A common mistake that `takeUntilDestroyed` *doesn't* solve on its own is the incorrect placement when using higher-order mapping operators like `switchMap`, `mergeMap`, `concatMap`, or `exhaustMap`. These operators create *inner* observables.

**The Pitfall:** If you place `takeUntilDestroyed` *before* the higher-order operator, it will only complete the *outer* observable. The inner observable might continue to run, causing a memory leak.

**INCORRECT - Potential Leak:**
```typescript
// INCORRECT placement
someTrigger$.pipe(
  takeUntilDestroyed(), // Placed BEFORE switchMap
  switchMap(() => someInnerObservable$) // The inner subscription may leak
).subscribe();
```

**CORRECT - No Leak:**
The solution is simple: **always place `takeUntilDestroyed` as the last operator in the pipe.** This ensures that it acts on the final subscription that is passed to `.subscribe()`, including any inner subscriptions created along the way.

```typescript
// CORRECT placement
someTrigger$.pipe(
  switchMap(() => someInnerObservable$),
  takeUntilDestroyed() // Placed LAST
).subscribe();
```

- **Resource:** [Avoid Memory Leaks in Angular When Using takeUntil with Higher-Order RxJS Operators](https://dev.to/petersaktor/avoid-memory-leaks-in-angular-when-using-takeuntil-with-higher-order-rxjs-operators-268m)

## Other Disciplined Subscription Patterns

-   **`toSignal`:** As covered in the previous lesson, `toSignal` is the best way to consume an observable in a component template. It handles subscription management automatically. Use it whenever you just need to display the value.
-   **Async Pipe (`| async`):** The original solution for templates. Like `toSignal`, it handles subscription and unsubscription automatically. It's still a perfectly valid and useful pattern.
-   **Finite Observables:** Observables that are guaranteed to complete on their own (like those from `HttpClient`) do not need manual cleanup. The `http.get()` observable emits one value and then completes, cleaning itself up.

By using `toSignal` for template bindings and `takeUntilDestroyed` (correctly placed!) for imperative subscriptions, you can build complex, reactive Angular applications that are free from memory leaks.