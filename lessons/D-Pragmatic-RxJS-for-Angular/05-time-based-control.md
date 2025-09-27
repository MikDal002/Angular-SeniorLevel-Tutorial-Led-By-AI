# Lesson 5: Time-Based Control (debounce, throttle, jittered retry)

RxJS provides powerful operators for controlling the flow of events over time. These are essential for creating responsive user interfaces that don't overload servers with requests, and for building resilient network logic that can gracefully handle transient failures.

This lesson covers three key time-based patterns: debouncing, throttling, and exponential backoff retries.

## `debounceTime`: Waiting for a Pause

The `debounceTime` operator discards emitted values from a source observable until a particular time span has passed without another emission. It then emits the most recent value.

-   **Analogy:** You're in a noisy room and decide you'll only speak when there's been a 2-second pause in the conversation.
-   **When to use it:** This is the perfect operator for "search-as-you-type" functionality. You don't want to send an HTTP request for every single keystroke. Instead, you wait until the user has stopped typing for a brief period (e.g., 300ms) and then send the request.

```typescript
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';

searchInput.valueChanges.pipe(
  debounceTime(300), // Wait for a 300ms pause
  distinctUntilChanged(), // Only emit if the value has changed
  switchMap(query => this.api.search(query))
).subscribe(results => { /* ... */ });
```

- **Resource:** [RxJS debounceTime vs. throttleTime](https://medium.com/@tugbaakyolsener/rxjs-throttletime-vs-debouncetime-a-comparison-c0cd9f4d4740)

## `throttleTime`: Ignoring Subsequent Emissions

The `throttleTime` operator emits a value from the source observable, then ignores subsequent source emissions for a specified duration. After the duration has passed, it will emit the next value from the source.

-   **Analogy:** You're using a machine gun that can only fire once every 2 seconds. You can pull the trigger as much as you want, but a bullet will only come out every 2 seconds.
-   **When to use it:** This is useful for rate-limiting events that can fire very rapidly, such as mouse movements, window resizing, or button spamming. It ensures that the event handler is not executed excessively.

```typescript
import { throttleTime } from 'rxjs/operators';

fromEvent(document, 'mousemove').pipe(
  throttleTime(100) // Emit at most one mousemove event every 100ms
).subscribe(event => {
  // Update UI based on mouse position without overwhelming the browser
});
```

### Debounce vs. Throttle: Key Difference
-   **Debounce:** Emits a value *after* a period of inactivity. Good for when you only care about the final state.
-   **Throttle:** Emits a value, then enters a "cooldown" period. Good for when you want to handle events at a regular, controlled pace.

## Resilient Retries: Exponential Backoff with Jitter

When an HTTP request fails, simply retrying it immediately is often a bad idea. If the server is overloaded, immediate retries will only make the problem worse. A much more robust strategy is **exponential backoff with jitter**.

-   **Exponential Backoff:** The delay between retries increases exponentially (e.g., 1s, 2s, 4s, 8s). This gives the server time to recover.
-   **Jitter:** A small, random amount of time is added to each delay. This prevents a "thundering herd" scenario where many clients, all experiencing the same error, retry in synchronized waves. The randomness spreads out the retry attempts.

The `retry` operator in RxJS can be configured to implement this logic.

### Example: A Custom Retry Strategy

Let's create a reusable function that implements this strategy.

```typescript
// src/shared/api/retry.strategy.ts
import { Observable, timer, throwError } from 'rxjs';
import { mergeMap, finalize } from 'rxjs/operators';

export const genericRetryStrategy = ({
  maxRetryAttempts = 3,
  scalingDuration = 1000,
  excludedStatusCodes = []
}: {
  maxRetryAttempts?: number,
  scalingDuration?: number,
  excludedStatusCodes?: number[]
} = {}) => (attempts: Observable<any>) => {
  return attempts.pipe(
    mergeMap((error, i) => {
      const retryAttempt = i + 1;
      // if maximum number of retries have been met
      // or response is a status code we don't want to retry, throw error
      if (
        retryAttempt > maxRetryAttempts ||
        excludedStatusCodes.find(e => e === error.status)
      ) {
        return throwError(() => error);
      }

      // calculate delay with exponential backoff and jitter
      const delay = Math.pow(2, retryAttempt) * scalingDuration;
      const jitter = Math.random() * scalingDuration; // Add randomness
      console.log(
        `Attempt ${retryAttempt}: retrying in ${Math.round(delay + jitter)}ms`
      );
      return timer(delay + jitter);
    }),
    finalize(() => console.log('Retry strategy complete.'))
  );
};
```

**How to use it:**
You can now apply this strategy to your HTTP calls.

```typescript
import { retry } from 'rxjs/operators';
import { genericRetryStrategy } from './retry.strategy';

this.httpClient.get('/api/some-flaky-endpoint').pipe(
  retry(genericRetryStrategy({
    maxRetryAttempts: 4,
    scalingDuration: 500,
    excludedStatusCodes: [404, 401] // Don't retry "Not Found" or "Unauthorized"
  }))
).subscribe();
```
This creates a highly resilient data-fetching mechanism that can automatically recover from transient network or server issues without overwhelming the backend.

- **Resource:** [Power of RxJS when using exponential backoff](https://angular.love/power-of-rxjs-when-using-exponential-backoff/)
- **Resource:** [Timeouts, retries, and backoff with jitter (AWS Builders' Library)](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/)

---

## ✅ Verifiable Outcome

You can verify these time-based operators by observing console logs and network requests.

1.  **Test `debounceTime`:**
    -   Create a component with a search input. Bind its `valueChanges` to a stream that uses `debounceTime(500)` and logs to the console.
    -   Run the application and type quickly into the input field.
    -   **Expected Result:** The console should not log on every keystroke. It should only log a single value, 500ms after you *stop* typing.

2.  **Test `throttleTime`:**
    -   Create a component that listens to the `mousemove` event on the `document`. Pipe this event through `throttleTime(1000)` and log to the console.
    -   Run the application and move your mouse continuously over the page.
    -   **Expected Result:** The console should only log a new event at most once per second, no matter how much you move the mouse.

3.  **Test the Retry Strategy:**
    -   Create a component with a button that triggers an `HttpClient` call to a non-existent endpoint (e.g., `/api/flaky`).
    -   Apply the `genericRetryStrategy` to this `HttpClient` call.
    -   Run the application, open the DevTools "Network" and "Console" tabs, and click the button.
    -   **Expected Result:** You will see the first request fail with a 404 in the Network tab. In the console, you will see the log "Attempt 1: retrying in...". A second request will be sent after the calculated delay, which will also fail. This will repeat until the `maxRetryAttempts` is reached, at which point the final error is thrown and the "Retry strategy complete." message is logged.