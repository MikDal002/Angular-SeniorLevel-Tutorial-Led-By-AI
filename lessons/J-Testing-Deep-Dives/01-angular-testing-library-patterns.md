# Lesson 1: Angular Testing Library Patterns

Traditional Angular component testing often relies on implementation details. You might query for a component by its CSS class or check the value of a component property. This leads to brittle tests that break when you refactor the component's internal structure, even if the user-facing behavior hasn't changed.

**Angular Testing Library (ATL)** is a testing utility built on the principle that **your tests should resemble how users interact with your app.** It encourages you to query and interact with the DOM in the same way a user would: by finding text, labels, and roles, not by relying on `id`s and CSS classes.

This approach leads to tests that are more readable, maintainable, and resilient to refactoring.

- **Resource:** [Official Angular Testing Library Documentation](https://testing-library.com/docs/angular-testing-library/intro)
- **Resource:** [Good testing practices with Angular Testing Library by Tim Deschryver](https://timdeschryver.dev/blog/good-testing-practices-with-angular-testing-library)

## The Core Idea: Test Behavior, Not Implementation

Consider a simple counter component.

```typescript
// counter.component.ts
@Component({
  selector: 'app-counter',
  template: `
    <p>Current Count: {{ count }}</p>
    <button (click)="increment()">Increment</button>
  `
})
export class CounterComponent {
  count = 0;
  increment() { this.count++; }
}
```

### The "Traditional" Test (Implementation-Focused)

A traditional test might check the component's internal `count` property and use `debugElement` to find the button.

```typescript
// traditional.spec.ts
it('should increment the count property when the button is clicked', () => {
  // ARRANGE
  const { component, fixture } = await render(CounterComponent);
  expect(component.count).toBe(0);

  // ACT
  const button = fixture.debugElement.query(By.css('button'));
  button.triggerEventHandler('click', null);
  fixture.detectChanges();

  // ASSERT
  expect(component.count).toBe(1); // <-- Testing an internal property
});
```
This test is coupled to the implementation detail that the state is stored in a property named `count`. If we renamed it to `value`, the test would break, even though the user sees the exact same thing.

### The ATL Test (User-Focused)

An ATL test interacts with the component just like a user. It looks for the text on the screen and finds the button by its accessible role.

-   **`render`**: Renders the component into the test DOM.
-   **`screen`**: A utility object with query methods to find elements the way a user would.
-   **`fireEvent`**: A utility to dispatch DOM events, like clicks.

```typescript
// atl.spec.ts
import { render, screen, fireEvent } from '@testing-library/angular';
import { CounterComponent } from './counter.component';

it('should display the new count after the increment button is clicked', async () => {
  // ARRANGE
  await render(CounterComponent);

  // Use `screen` to find elements by what the user sees.
  // Assert the initial state is correct from a user's perspective.
  expect(screen.getByText('Current Count: 0')).toBeInTheDocument();

  // ACT
  // Find the button by its accessible role and name.
  const incrementButton = screen.getByRole('button', { name: /increment/i });
  fireEvent.click(incrementButton);

  // ASSERT
  // Assert the outcome from a user's perspective.
  // The old text is gone, and the new text is present.
  expect(screen.queryByText('Current Count: 0')).not.toBeInTheDocument();
  expect(screen.getByText('Current Count: 1')).toBeInTheDocument();
});
```

## Why the ATL Approach is Better

1.  **Resilience:** The ATL test doesn't care if the property is named `count` or `value`. It doesn't care if the button has a CSS class of `.increment-button`. It only cares that a button with the text "Increment" exists and that clicking it causes the text "Current Count: 1" to appear on the screen. You can refactor the component's internals freely without breaking the test.

2.  **Accessibility:** By querying for elements by their accessible role, name, and label text, you are implicitly testing and enforcing that your application is accessible. If you can't find a button by its role, it's likely not a real `<button>` element and is inaccessible to screen reader users.

3.  **Readability:** The test reads like a user story: "When I see the initial count and click the 'Increment' button, I should see the new count."

## Key ATL Query Methods

Always use the most specific query that matches how a user would find the element. The recommended priority order is:

1.  **`getByRole`**: Finds elements by their ARIA role (e.g., `button`, `navigation`, `heading`). This is the most resilient query.
2.  **`getByLabelText`**: Finds the `input` associated with a given `<label>`.
3.  **`getByPlaceholderText`**: Finds an `input` by its placeholder.
4.  **`getByText`**: Finds an element by its text content.
5.  **`getByDisplayValue`**: Finds a form element (`input`, `textarea`, `select`) by its current displayed value.

...and as a last resort:

6.  **`getByTestId`**: Finds an element by a `data-testid` attribute. This should be used only when you cannot find an element by any other user-visible means.

By adopting Angular Testing Library, you shift your mindset from testing what your code *is* to testing what your code *does* from the perspective of a user, leading to more meaningful and robust tests.