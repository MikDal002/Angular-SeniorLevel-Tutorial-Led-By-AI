# Lesson 1: Core Operator Toolkit

RxJS offers a vast library of over 100 operators, which can be intimidating for newcomers. However, in day-to-day Angular development, a much smaller, pragmatic subset of these operators will solve the vast majority of your problems.

This lesson provides a "core toolkit" of essential operators, grouped by their primary function. Mastering this toolkit will enable you to handle most UI flows and side effects cleanly and efficiently.

- **Primary Resource:** [RxJS Operators Documentation](https://rxjs.dev/guide/operators)
- **Helpful Guide:** [Mastering RxJS Operators: Unlocking the Power of Angular](https://blog.bitsrc.io/mastering-rxjs-operators-unlocking-the-power-of-angular-af375e45d4eb)

---

## 1. Transformation Operators

These operators transform the values emitted by an observable.

### `map`
The most common operator. It applies a projection function to each value from the source observable.
- **Use Case:** Transforming an API response object into a different shape for your UI.
```typescript
import { map } from 'rxjs/operators';

httpClient.get<UserApiResponse>('/api/users/1').pipe(
  map(apiUser => ({ id: apiUser.uuid, name: apiUser.fullName }))
).subscribe(uiUser => { /* ... */ });
```

### `scan`
Similar to `Array.prototype.reduce`. It applies a function to each value and an accumulator, emitting the accumulated value for each source emission.
- **Use Case:** Managing state over time, like accumulating a total or building up an array of actions.
```typescript
import { scan } from 'rxjs/operators';

action$.pipe(
  scan((acc, curr) => [...acc, curr], [])
).subscribe(history => console.log(history)); // Logs an array of all actions so far
```

---

## 2. Filtering Operators

These operators selectively emit values from a source observable based on a condition.

### `filter`
Emits only the values that pass a provided predicate function.
- **Use Case:** Ignoring falsy values or only acting on specific events.
```typescript
import { filter } from 'rxjs/operators';

form.valueChanges.pipe(
  filter(formValue => formValue.isValid)
).subscribe(validValue => { /* ... */ });
```

### `take`
Emits a specified number of values from the start of a stream and then completes.
- **Use Case:** Taking only the first value from a stream, which is common when you only need the initial state.
```typescript
import { take } from 'rxjs/operators';

settings$.pipe(take(1)).subscribe(initialSettings => { /* ... */ });
```

### `distinctUntilChanged`
Only emits when the current value is different from the last. For objects, it performs a reference check by default, but you can provide a custom comparator.
- **Use Case:** Preventing duplicate emissions, especially in streams of user input or state selectors.
```typescript
import { distinctUntilChanged } from 'rxjs/operators';

searchQuery$.pipe(distinctUntilChanged()).subscribe(uniqueQuery => { /* ... */ });
```

---

## 3. Combination Operators

These operators work with multiple source observables to create a single output observable.

### `combineLatest`
When any source observable emits, it emits the latest value from each source as an array. It will not emit until *all* source observables have emitted at least once.
- **Use Case:** Combining several streams of data that are all needed to render a view (e.g., user profile, user settings, and user permissions).
```typescript
import { combineLatest } from 'rxjs';

combineLatest([user$, settings$, permissions$]).subscribe(
  ([user, settings, permissions]) => { /* Now you have everything you need */ }
);
```

### `forkJoin`
When all source observables complete, it emits an array of the last-emitted value from each.
- **Use Case:** Making multiple parallel HTTP requests and waiting for all of them to complete before proceeding.
```typescript
import { forkJoin } from 'rxjs';

forkJoin({
  user: httpClient.get('/api/user'),
  posts: httpClient.get('/api/posts')
}).subscribe(results => {
  // results.user and results.posts are available here
});
```

---

## 4. Flattening Operators (Higher-Order Mapping)

These operators are crucial for managing inner observables, such as when one asynchronous operation depends on the result of another (e.g., fetching a user, then fetching their posts).

- **`switchMap`:** The most common choice for UI-related flows. Subscribes to a new inner observable and **cancels the previous inner subscription**.
- **`mergeMap`:** Subscribes to all inner observables and emits their values as they arrive. Good for parallel operations.
- **`concatMap`:** Subscribes to inner observables one after another, in order. Waits for the current one to complete before starting the next.
- **`exhaustMap`:** Ignores new inner observables while the current one is still running.

*(These will be covered in detail in the next lesson).*

---

## 5. Utility & Side-Effect Operators

### `tap`
Perform a side effect for every emission in the source observable. It does not modify the stream.
- **Use Case:** Logging values for debugging without altering the data flow.
```typescript
import { tap } from 'rxjs/operators';

data$.pipe(
  tap(value => console.log('Value before map:', value)),
  map(value => value * 2),
  tap(value => console.log('Value after map:', value))
).subscribe();
```

### `startWith`
Emit a given value immediately on subscription, before any values from the source observable are emitted.
- **Use Case:** Providing an initial state for a UI, such as a loading indicator or an empty array.
```typescript
import { startWith } from 'rxjs/operators';

posts$.pipe(
  startWith([]) // Immediately emit an empty array so the UI doesn't crash
).subscribe(posts => { /* ... */ });
```

---

## 6. Error Handling Operators

### `catchError`
Catches errors on the source observable and allows you to return a new observable or throw a new error.
- **Use Case:** Handling HTTP errors gracefully by returning a default value or a user-friendly error object.
```typescript
import { catchError, of } from 'rxjs';

data$.pipe(
  catchError(error => {
    console.error('An error occurred:', error);
    return of({ error: true, message: 'Could not fetch data' }); // Return a safe value
  })
).subscribe();
```

By focusing on this core set of operators, you can build powerful, reactive, and resilient Angular applications.