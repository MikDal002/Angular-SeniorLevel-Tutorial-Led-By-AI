# Lesson 3: Jest Unit Tests with Time Control

Testing asynchronous code, especially logic involving time (like `debounceTime`, `delay`, `throttleTime`), can be tricky. Relying on real-time delays (`setTimeout` in your tests) makes your test suite slow and flaky.

The solution is to control time itself. This lesson covers two ways to do this: using **Jest's fake timers** for simple cases and the more powerful **RxJS `TestScheduler`** for complex observable streams.

## 1. Simple Time Control with Jest Fake Timers

Jest can mock out timer functions like `setTimeout`, `setInterval`, and `Date.now()`, allowing you to manually advance time in your tests. This is perfect for testing simple debounced functions or components.

- **Resource:** [Jest Timer Mocks Documentation](https://jestjs.io/docs/timer-mocks)

### The Scenario: Testing a Debounced Search Input

Imagine a component that takes a search query, debounces it, and emits an event.

```typescript
// search-input.component.ts
@Component({ /* ... */ })
export class SearchInputComponent implements OnInit, OnDestroy {
  @Output() search = new EventEmitter<string>();
  private query$ = new Subject<string>();
  private sub: Subscription;

  ngOnInit() {
    this.sub = this.query$.pipe(
      debounceTime(300)
    ).subscribe(query => this.search.emit(query));
  }

  onInput(query: string) {
    this.query$.next(query);
  }

  ngOnDestroy() { this.sub.unsubscribe(); }
}
```

### The Test with Fake Timers

```typescript
// search-input.component.spec.ts
describe('SearchInputComponent', () => {
  // 1. Tell Jest to use fake timers for this test suite.
  beforeEach(() => {
    jest.useFakeTimers();
  });

  it('should not emit a search event immediately', () => {
    const { component, searchSpy } = setup(); // A helper to render the component
    component.onInput('a');
    expect(searchSpy).not.toHaveBeenCalled();
  });

  it('should emit a search event after 300ms have passed', () => {
    const { component, searchSpy } = setup();
    component.onInput('a');

    // 2. Manually advance time by 300ms.
    jest.advanceTimersByTime(300);

    expect(searchSpy).toHaveBeenCalledWith('a');
    expect(searchSpy).toHaveBeenCalledTimes(1);
  });

  it('should only emit the latest value if input changes within the debounce time', () => {
    const { component, searchSpy } = setup();
    component.onInput('a');
    jest.advanceTimersByTime(100); // 100ms pass
    component.onInput('ab');
    jest.advanceTimersByTime(100); // 200ms pass
    component.onInput('abc');

    // 3. Advance time past the final debounce threshold.
    jest.advanceTimersByTime(300);

    expect(searchSpy).toHaveBeenCalledWith('abc');
    expect(searchSpy).toHaveBeenCalledTimes(1);
  });
});
```

## 2. Advanced Time Control with RxJS `TestScheduler`

For testing complex RxJS pipelines, the `TestScheduler` is a more powerful tool. It allows you to define and test observables in a synchronous and deterministic way using **marble diagrams**.

-   **Virtual Time:** The `TestScheduler` doesn't use real time; it uses "virtual time frames."
-   **Marble Diagrams:** A string representation of events happening over virtual time.
    -   `-`: A single frame of virtual time.
    -   `a`, `b`, `c`...: An emission of a value.
    -   `|`: Successful completion of the stream.
    -   `#`: An error.
    -   `()`: Grouping of synchronous emissions.

- **Resource:** [RxJS Marble Testing Guide](https://rxjs.dev/guide/testing/marble-testing)

### The Test with `TestScheduler`

Let's test the same `debounceTime(300)` logic using the `TestScheduler`.

```typescript
import { TestScheduler } from 'rxjs/testing';

describe('DebounceTime with TestScheduler', () => {
  let scheduler: TestScheduler;

  beforeEach(() => {
    scheduler = new TestScheduler((actual, expected) => {
      // Assert that the actual output matches the expected marble diagram.
      expect(actual).toEqual(expected);
    });
  });

  it('should only emit the last value after a pause', () => {
    // 1. Use the scheduler's .run() helper.
    scheduler.run(helpers => {
      const { cold, expectObservable } = helpers;

      // 2. Define the source observable using a marble diagram.
      // 'a' emits at 10ms, 'b' at 200ms, 'c' at 550ms.
      const source$ = cold('-a--b----c|', { a: 'A', b: 'B', c: 'C' });

      // 3. Define the expected output observable.
      // debounceTime(300) will wait after each emission.
      // 'a' is ignored because 'b' comes too soon.
      // 'b' is emitted at 500ms (200ms + 300ms debounce).
      // 'c' is emitted at 850ms (550ms + 300ms debounce).
      const expectedMarble = '-----b----c|';
      const expectedValues = { b: 'B', c: 'C' };

      const result$ = source$.pipe(debounceTime(300, scheduler));

      // 4. Assert that the result matches the expectation.
      expectObservable(result$).toBe(expectedMarble, expectedValues);
    });
  });
});
```

### Why Use `TestScheduler`?

-   **Declarative:** Marble diagrams provide a clear, visual, and declarative way to define complex asynchronous streams.
-   **Precise:** It gives you complete control over the timing and emission of values, making it ideal for testing complex operators like `combineLatest`, `mergeMap`, `retry`, etc.
-   **Powerful:** It's the standard for testing libraries built with RxJS and is the most robust way to test your own complex observable pipelines.

While Jest's fake timers are great for simple component-level tests, mastering the `TestScheduler` is essential for writing reliable unit tests for your core RxJS-based services and effects.