# Lesson 2: Signals–RxJS Interop

While Angular Signals offer a new and powerful reactivity model, RxJS is not going away. It remains the best tool for handling complex asynchronous operations, especially event-based streams (like `HttpClient` responses, router events, or WebSocket messages).

A key part of adopting signals is knowing how to bridge the two worlds. The `@angular/core/rxjs-interop` package provides two essential utilities for this: `toSignal` and `toObservable`.

## Converting Observables to Signals with `toSignal`

The most common interop scenario is consuming an observable stream (e.g., from a service) within a signal-based component. The `toSignal` function makes this trivial. It subscribes to an observable and creates a signal that is updated with the latest emitted value.

### Key Features of `toSignal`:

-   **Automatic Unsubscription:** `toSignal` automatically subscribes to the observable and, crucially, **unsubscribes** when the component it's called in is destroyed. This prevents memory leaks without any manual cleanup.
-   **Initial Value:** Signals must always have a value, but observables might not emit one synchronously. `toSignal` requires you to provide an `initialValue` to ensure the signal is always defined.
-   **Error and Completion:** The signal returned by `toSignal` does not propagate error or complete notifications from the observable. You should handle errors within the observable pipeline itself (e.g., with the `catchError` operator).

### Example: Consuming a Data Stream

Imagine a service that returns an observable stream of data.

**Data Service:**
```typescript
// data.service.ts
import { Injectable } from '@angular/core';
import { interval, map } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class DataService {
  getDataStream() {
    return interval(1000).pipe(map(i => `Data packet #${i + 1}`));
  }
}
```

**Component using `toSignal`:**
```typescript
// my-component.ts
import { Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { DataService } from './data.service';

@Component({
  selector: 'app-my',
  template: `
    <p>Latest data: {{ data() }}</p>
  `
})
export class MyComponent {
  private dataService = inject(DataService);

  // Convert the observable stream to a signal.
  data = toSignal(this.dataService.getDataStream(), {
    initialValue: 'Waiting for data...'
  });
}
```

In this example, the `data` signal will be updated every second with the new value from the `getDataStream` observable. There's no need for `| async` pipes or manual subscription management in the component.

- **Resource:** [Official `toSignal` documentation](https://angular.io/guide/rxjs-interop#tosignal)

## Converting Signals to Observables with `toObservable`

Sometimes you need to do the opposite: expose a signal's value as an observable stream. This is useful when you need to use RxJS operators on a signal's value or when interoperating with a third-party library that expects an observable.

The `toObservable` function creates an observable that emits the current value of a signal and then a new value every time the signal changes.

### Key Features of `toObservable`:

-   **Initial Emission:** The created observable emits the signal's current value immediately upon subscription.
-   **Automatic Completion:** The observable automatically completes when the component it's called in is destroyed.

### Example: Debouncing a Signal Input

Let's say you have a search input whose value is stored in a signal. You want to trigger a search API call, but only after the user has stopped typing for 300ms. This is a perfect use case for `toObservable` combined with RxJS operators.

```typescript
// search.component.ts
import { Component, inject, signal } from '@angular/core';
import { toObservable } from '@angular/core/rxjs-interop';
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';
import { SearchService } from './search.service';

@Component({
  selector: 'app-search',
  template: `
    <input type="text" [value]="query()" (input)="onQueryChange($event)" />
    <!-- ... display results ... -->
  `
})
export class SearchComponent {
  private searchService = inject(SearchService);
  query = signal('');

  // Convert the query signal to an observable to use RxJS operators.
  private query$ = toObservable(this.query);

  // The final results stream.
  results$ = this.query$.pipe(
    debounceTime(300),
    distinctUntilChanged(),
    switchMap(query => this.searchService.search(query))
  );

  onQueryChange(event: Event) {
    const input = event.target as HTMLInputElement;
    this.query.set(input.value);
  }
}
```

In this example:
1.  The `query` signal holds the live value of the input field.
2.  `toObservable(this.query)` creates a `query$` observable that emits a new value every time the `query` signal changes.
3.  We then use standard RxJS operators (`debounceTime`, `distinctUntilChanged`, `switchMap`) to create a clean, efficient, and reactive search feature.

- **Resource:** [Official `toObservable` documentation](https://angular.io/guide/rxjs-interop#toobservable)

---

## ✅ Verifiable Outcome

After completing this lesson, you can verify your understanding by implementing the two main examples.

1.  **Test `toSignal`:**
    -   Create the `DataService` and `MyComponent` as described in the first example.
    -   Display `MyComponent` in your application.
    -   **Expected Result:** The page should initially display "Latest data: Waiting for data...". After one second, the text should update to "Latest data: Data packet #1", and then continue to update every second. This confirms you have successfully converted an observable stream into a reactive signal.

2.  **Test `toObservable`:**
    -   Create the `SearchComponent` and a mock `SearchService` as described in the second example.
    -   In the `SearchComponent`, add a subscription to the `results$` observable to log its output to the console: `results$.subscribe(console.log);`.
    -   Display the component and type quickly into the input field (e.g., "test search").
    -   **Expected Result:** You should see that the `console.log` only fires *once*, a short moment after you stop typing. This confirms you have successfully converted a signal into an observable and applied RxJS operators (`debounceTime`) to it.