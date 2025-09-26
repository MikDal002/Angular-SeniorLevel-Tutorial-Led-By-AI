# Lesson 1: Signals for Local State and Derivations

Angular Signals provide a powerful and fine-grained reactivity model that simplifies state management within components. They are perfect for handling local component state and creating derived values that automatically update when their dependencies change.

This lesson explores how to use `signal()` to manage state and `computed()` to create derived values.

## Managing Local State with `signal()`

A `signal` is a wrapper around a value that can notify interested consumers when that value changes. For local component state, this means you can replace simple properties and `BehaviorSubject` instances with signals to get automatic, optimized change detection.

- **Creating a Signal:** To create a signal, use the `signal()` function, passing the initial value.
- **Reading a Signal:** To read the value of a signal, you call it like a function: `mySignal()`.
- **Updating a Signal:** Writable signals have three methods to change their value:
    -   `.set(newValue)`: Directly sets the value.
    -   `.update(updateFn)`: Updates the value based on the current value.
    -   `.mutate(mutationFn)`: For complex objects, you can mutate the value in place (use with caution, as this can be less predictable than immutable updates).

### Example: A Simple Counter

Let's build a counter component using signals for its state.

```typescript
// counter.component.ts
import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-counter',
  template: `
    <p>Count: {{ count() }}</p>
    <button (click)="increment()">Increment</button>
    <button (click)="decrement()">Decrement</button>
    <button (click)="reset()">Reset</button>
  `
})
export class CounterComponent {
  // Create a writable signal for the count.
  count = signal(0);

  increment() {
    // Use .update() for safe, immutable updates.
    this.count.update(currentValue => currentValue + 1);
  }

  decrement() {
    this.count.update(currentValue => currentValue - 1);
  }

  reset() {
    // Use .set() to replace the value directly.
    this.count.set(0);
  }
}
```

Because we are reading the `count` signal in the template (`{{ count() }}`), Angular knows that this component depends on the signal. Whenever the signal is updated, Angular will automatically mark this component for change detection, ensuring the UI is always in sync.

- **Resource:** [Angular Signals Explained: A Comprehensive Guide](https://medium.com/@kashif_khan/angular-signals-explained-a-comprehensive-guide-for-developers-aa5317256344)

## Creating Derived Values with `computed()`

Often, you have state that is calculated based on other pieces of state. For example, a full name is derived from a first name and a last name. A `computed` signal is perfect for this.

A `computed` signal is a **read-only** signal that derives its value from a calculation involving other signals. The calculation function is re-executed automatically whenever any of its dependent signals change.

### Example: Derived Values

Let's expand our counter example. We want to display a message if the count is even or odd, and we want to disable the decrement button if the count is zero.

```typescript
// counter.component.ts
import { Component, signal, computed } from '@angular/core';

@Component({
  selector: 'app-counter',
  template: `
    <p>Count: {{ count() }}</p>
    <p>The count is {{ evenOrOdd() }}.</p>
    <button (click)="increment()">Increment</button>
    <button (click)="decrement()" [disabled]="isDecrementDisabled()">Decrement</button>
  `
})
export class CounterComponent {
  count = signal(0);

  // Create a computed signal that derives its value from `count`.
  evenOrOdd = computed(() => {
    return this.count() % 2 === 0 ? 'even' : 'odd';
  });

  // Another computed signal for the button's disabled state.
  isDecrementDisabled = computed(() => this.count() === 0);

  increment() {
    this.count.update(val => val + 1);
  }

  decrement() {
    this.count.update(val => val - 1);
  }
}
```

### How `computed()` Works

1.  **Dependency Tracking:** When `evenOrOdd` is created, Angular tracks which signals are read inside its computation function (in this case, `this.count()`).
2.  **Lazy Evaluation:** The value of a computed signal is only calculated the first time it's read.
3.  **Memoization:** The calculated value is cached. As long as its dependent signals (`count`) don't change, subsequent reads of `evenOrOdd()` will return the cached value without re-running the calculation.
4.  **Automatic Updates:** When `count` is updated, Angular knows that `evenOrOdd` is now "dirty" and needs to be recalculated the next time it's read.

This system is incredibly efficient. Computations only run when necessary, and the dependency graph is managed automatically by the framework.

- **Resource:** [Angular Signals: A Comprehensive Introduction](https://dev.to/nikhil6076/angular-signals-a-comprehensive-introduction-45h2)

By using `signal()` for your raw state and `computed()` for derived values, you can create highly reactive and performant components with clean, declarative, and easy-to-understand state management logic.