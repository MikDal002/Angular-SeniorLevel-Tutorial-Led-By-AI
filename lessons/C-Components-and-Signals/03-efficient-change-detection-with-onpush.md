# Lesson 3: Efficient Change Detection with OnPush and Signals

In modern Angular, performance is not just about choosing the right algorithm; it's about being smart with change detection. The combination of the `OnPush` strategy and Signals is the cornerstone of building highly efficient, performant applications.

This lesson explains why `OnPush` is still the recommended default and how it works with Signals to prevent unnecessary checks and re-renders.

## Why `OnPush` is Still Essential

Even with the fine-grained reactivity of Signals, `OnPush` plays a crucial role. By setting a component's change detection strategy to `OnPush`, you are telling Angular:

> "Do not check this component or any of its children unless you have a specific reason to believe it has changed."

This fundamentally changes the change detection process from "check everything by default" to "check nothing by default." This is a massive performance win, as it allows Angular to skip entire component subtrees that don't need to be updated.

- **Resource:** [Optimizing Angular Change Detection with OnPush](https://dev.to/atheodosiou/optimizing-angular-change-detection-with-onpush-skipping-subtrees-for-performance-45md)

## How Signals and `OnPush` Work Together

Signals and `OnPush` are a perfect match. A component with `changeDetection: ChangeDetectionStrategy.OnPush` will be checked and re-rendered if any of the following are true:

1.  An `@Input()` reference has changed.
2.  A DOM event the component is listening to has fired (e.g., a `(click)` handler).
3.  Change detection is manually triggered (e.g., via `markForCheck()`).
4.  An `async` pipe in the template emits a new value.
5.  **A signal that is read in the template has been updated.**

This last point is the key. When you use a signal in your template (`{{ mySignal() }}`), Angular creates a dependency. When that signal's value changes, Angular knows that *only this specific component* needs to be checked.

### The "Glacier" Effect

Think of your component tree as a glacier. With the default change detection strategy, any event causes the entire glacier to shift and groan. With `OnPush`, the glacier is frozen solid.

When a signal is updated, it's like a targeted seismic probe that "wakes up" only the specific components that depend on it, leaving the rest of the glacier untouched. This is fine-grained reactivity at its best.

### The Ultimate Optimization

There's even a further optimization. When a signal is updated in an `OnPush` component, Angular is smart enough to check *only that component and its children*. It can often skip checking the component's ancestors if they are not also marked as dirty. This is a significant improvement over older patterns where `markForCheck()` would mark the entire path to the root as dirty.

- **Resource:** [Should You Pair Signals & OnPush?](https://dev.to/this-is-angular/should-you-pair-signals-onpush-1jko) - A great discussion on the topic.
- **Resource:** [Stack Overflow: Should we use OnPush with Signals?](https://www.reddit.com/r/Angular2/comments/1ihk8vl/should_we_use_changedetectionstrategyonpush_with/) - An excellent, detailed explanation of the mechanics.

## Best Practices for "Careful Bindings"

To maximize the benefits of this pattern, you need to be mindful of what you do in your templates.

1.  **Read Signals in the Template:** The magic happens when you call the signal function directly in the template: `{{ mySignal() }`. This is what establishes the reactive link.

2.  **Avoid Unnecessary Function Calls:** Avoid calling complex functions in your template bindings.
    ```html
    <!-- BAD: This function runs on every change detection cycle -->
    <p>{{ calculateComplexValue() }}</p>

    <!-- GOOD: The computed signal only recalculates when its dependencies change -->
    <p>{{ myComputedSignal() }}</p>
    ```
    Every function call in a template binding is a potential performance bottleneck. If you need to derive a value, use a `computed` signal in your component class.

3.  **Use Pure Pipes:** For transformations, use pure pipes. A pure pipe is only re-evaluated when its input value changes, which fits perfectly with the `OnPush` philosophy.
    ```html
    <!-- GOOD: The date pipe only runs when myDateSignal() changes -->
    <p>{{ myDateSignal() | date:'short' }}</p>
    ```

## Conclusion

---

## ✅ Verifiable Outcome

This lesson is more conceptual, but you can verify the behavior with a small experiment.

1.  **Create Two Components:**
    -   Create a `ParentComponent` and a `ChildComponent`.
    -   In `ParentComponent`, have a signal `parentSignal = signal(0)` and a button that increments it.
    -   In `ChildComponent`, set `changeDetection: ChangeDetectionStrategy.OnPush`. Add a `console.log('ChildComponent change detection ran')` inside its template (e.g., in a getter or a function call, which is normally an anti-pattern but useful for this specific demonstration).
    -   Display the `ChildComponent` inside the `ParentComponent`'s template.

2.  **Run and Test:**
    -   Run the application and open the developer console.
    -   Click the button in the `ParentComponent` to update its signal.
    -   **Expected Result:** You will see logs from the `ParentComponent`'s change detection, but you should **not** see the "ChildComponent change detection ran" message. This proves that `OnPush` prevented Angular from checking the child subtree unnecessarily.

3.  **Add a Signal Input:**
    -   Now, pass the `parentSignal` into the `ChildComponent` as an `@Input()`.
    -   Read this input signal in the `ChildComponent`'s template.
    -   Run the test again.
    -   **Expected Result:** Now when you click the button in the parent, you **will** see the "ChildComponent change detection ran" message, because the child's signal dependency was updated, giving Angular a valid reason to check it.