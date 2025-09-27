# Lesson 2: Concurrency Semantics (switch/concat/exhaust/merge)

When you have an observable that emits other observables (a "higher-order" observable), you need a strategy for how to handle these "inner" streams. This is a common scenario in Angular, such as when a user action triggers an HTTP request.

`switchMap`, `concatMap`, `mergeMap`, and `exhaustMap` are four powerful operators that "flatten" these higher-order observables, but each has a different strategy for handling concurrency. Choosing the right one is crucial for building intuitive and predictable user experiences.

Let's use a common analogy: imagine a button that, when clicked, places an "order" (an inner observable, like an HTTP request). The outer observable is the stream of button clicks.

- **Resource:** [switchMap, mergeMap, concatMap & exhaustMap Explained](https://offering.solutions/blog/articles/2021/03/08/switchmap-mergemap-concatmap-exhaustmap-explained/)
- **Resource:** [RxJS: mergeMap vs switchMap vs concatMap vs exhaustMap](https://dev.to/kinginit/rxjs-mergemap-vs-switchmap-vs-concatmap-vs-exhaustmap-5gpg)

---

## `switchMap`: The "Cancel" Strategy

`switchMap` subscribes to the inner observable. If the outer observable emits a new value before the inner observable completes, `switchMap` **unsubscribes from the previous inner observable and "switches" to the new one.** It only ever cares about the latest inner observable.

-   **Analogy:** You place an order. Before it's delivered, you change your mind and place a new one. `switchMap` cancels the first order and processes only the new one.
-   **When to use it:** This is the most common operator for UI actions. It's perfect for scenarios where only the latest value matters, such as:
    -   **Search-as-you-type:** You only care about the results for the most recent search query.
    -   **Data fetching based on route parameters:** If the user navigates quickly between pages, you want to cancel the requests for the old pages and only get data for the current one.

```typescript
import { switchMap } from 'rxjs/operators';

searchQuery$.pipe(
  debounceTime(300),
  distinctUntilChanged(),
  switchMap(query => this.api.search(query)) // Cancels previous search requests
).subscribe(results => { /* ... */ });
```

---

## `concatMap`: The "Queue" Strategy

`concatMap` processes inner observables sequentially. It waits for the current inner observable to complete before subscribing to the next one. It maintains the order of the outer emissions.

-   **Analogy:** You place an order. `concatMap` waits for that order to be fully delivered before it will even consider placing the next one. It processes orders one at a time, in a queue.
-   **When to use it:** Use this when the order of operations is critical and you need to ensure one operation finishes before the next begins.
    -   **Sequential HTTP requests:** Performing a series of `POST`, `PUT`, or `DELETE` requests where the next one depends on the success of the previous one.
    -   **Saving a form:** Ensuring that a save operation completes fully before allowing another save to be triggered.

```typescript
import { concatMap } from 'rxjs/operators';

saveClicks$.pipe(
  concatMap(() => this.api.save(this.form.value)) // Waits for save to complete
).subscribe(response => { /* Saved successfully */ });
```

---

## `mergeMap` (or `flatMap`): The "Parallel" Strategy

`mergeMap` subscribes to every inner observable immediately and emits the values from all of them as they arrive. It runs operations in parallel.

-   **Analogy:** You place three orders. `mergeMap` sends all three to the kitchen at once. The food comes out as it's ready, regardless of which order was placed first.
-   **When to use it:** Use this when you want to perform multiple asynchronous operations concurrently and don't care about the order of their completion.
    -   **Uploading multiple files:** You want to kick off all the uploads at once.
    -   **Deleting multiple items:** A user selects several items and clicks "delete." You can fire off all the delete requests in parallel.

```typescript
import { mergeMap } from 'rxjs/operators';

deleteIds$.pipe(
  mergeMap(id => this.api.deleteItem(id)) // Fires off all delete requests concurrently
).subscribe(response => { /* An item was deleted */ });
```

---

## `exhaustMap`: The "Ignore" Strategy

`exhaustMap` subscribes to an inner observable. While that inner observable is active, it **ignores all new emissions** from the outer observable. It will only listen for new outer emissions after its current inner observable has completed.

-   **Analogy:** You place an order. While the kitchen is working on it, `exhaustMap` ignores any new orders you try to place. It won't accept a new order until the current one is delivered.
-   **When to use it:** This is perfect for preventing duplicate actions or spam clicks.
    -   **Login/Submit buttons:** A user clicks a "Login" button. You want to ignore any subsequent clicks while the login request is in flight to prevent submitting the form multiple times.
    -   **"Refresh" buttons:** Prevent the user from spamming the refresh button while data is already being fetched.

```typescript
import { exhaustMap } from 'rxjs/operators';

loginClicks$.pipe(
  exhaustMap(() => this.authService.login(this.credentials)) // Ignores clicks while logging in
).subscribe(response => { /* Logged in successfully */ });
```

---

### Summary

| Operator    | Strategy                                       | Use Case Example            |
| :---------- | :--------------------------------------------- | :-------------------------- |
| `switchMap` | Cancel previous, switch to new                 | Search-as-you-type          |
| `concatMap` | Queue operations, run one after another        | Sequential API calls        |
| `mergeMap`  | Run all operations in parallel                 | Uploading multiple files    |
| `exhaustMap`| Ignore new operations while one is in progress | Preventing double-submits |

---

## ✅ Verifiable Outcome

You can verify your understanding of these operators by building a small playground component.

1.  **Create the Playground Component:**
    -   Create a component with a single button.
    -   Create a `Subject` that emits when the button is clicked (`clicks$ = new Subject<void>()`).
    -   Create a mock "API call" observable that takes some time to complete:
        ```typescript
        mockApiCall(requestNumber: number) {
          console.log(`Request #${requestNumber} started...`);
          return of(`Response for #${requestNumber}`).pipe(
            delay(1000) // Simulate a 1-second network delay
          );
        }
        ```

2.  **Test Each Operator:**
    -   In your component, create a stream that pipes the `clicks$` subject through one of the four mapping operators. Subscribe to it and log the results.
        ```typescript
        // Example for exhaustMap
        let requestCount = 0;
        this.clicks$.pipe(
          exhaustMap(() => this.mockApiCall(++requestCount))
        ).subscribe(response => console.log(response));
        ```
    -   Run the application and open the console.
    -   **Test `exhaustMap`:** Click the button rapidly multiple times.
        -   **Expected Result:** You should see "Request #1 started..." logged once. After one second, you will see "Response for #1". All the clicks you made while the first request was in flight are ignored.
    -   **Test `switchMap`:** Change the operator to `switchMap`. Click the button, wait half a second, and click it again.
        -   **Expected Result:** You will see "Request #1 started..." followed by "Request #2 started...". After a total of 1.5 seconds, you will *only* see "Response for #2". The first request was cancelled.
    -   Repeat this process for `concatMap` (requests will happen sequentially, one after another) and `mergeMap` (requests will start in parallel and responses will arrive as they complete).