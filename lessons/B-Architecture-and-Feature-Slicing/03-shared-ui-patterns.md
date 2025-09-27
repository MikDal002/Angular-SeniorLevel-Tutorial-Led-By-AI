# Lesson 3: Shared UI Patterns (Presentational Components)

A key to a scalable and maintainable frontend architecture is the separation of concerns. One of the most effective ways to achieve this at the component level is by using the **Presentational and Container Component** pattern (also known as "Dumb" and "Smart" components).

In a Feature-Sliced Design (FSD) architecture, the `shared/ui` layer is the designated home for "dumb" or **Presentational Components**. These are reusable, pure UI components that form the building blocks of your application's design system.

## What is a Presentational Component?

A Presentational Component has one job: to display data and emit events when the user interacts with it. They are completely decoupled from the application's business logic.

### Characteristics of a Presentational Component:

1.  **Receives Data via `@Input()`:** It gets all the data it needs to display from its parent through input bindings.
2.  **Emits Events via `@Output()`:** It communicates with its parent by emitting events. It doesn't know what will happen when the event is emitted, only that it should be.
3.  **No Domain Logic:** It has no knowledge of where the data comes from (e.g., HTTP, state management) or what happens when an event is fired. It doesn't inject services that fetch data or perform business logic.
4.  **Highly Reusable:** Because it's decoupled from the application's logic, it can be used anywhere in the application that needs to display the same kind of UI.
5.  **Pure and Predictable:** Given the same inputs, it will always render the same output.

- **Seminal Article (React-based, but universally applicable):** [Presentational and Container Components by Dan Abramov](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0)

## What is a Container Component?

A Container Component, on the other hand, is the "smart" one. It's concerned with how things work.

### Characteristics of a Container Component:

1.  **Manages State:** It fetches data from services, subscribes to observables, and manages the state for itself and its child presentational components.
2.  **Injects Services:** It has dependencies on services that handle business logic (e.g., `HttpClient`, NgRx `Store`, feature-specific services).
3.  **Provides Data to Children:** It passes data down to presentational components via their `@Input()` bindings.
4.  **Handles Events from Children:** It listens for events from presentational components via their `@Output()` bindings and executes the appropriate business logic.
5.  **Tied to the Application:** It is often specific to a certain feature or page and is not easily reusable elsewhere.

- **Resource:** [Angular Architecture - Container vs Presentational Components](https://blog.angular-university.io/angular-component-design-how-to-avoid-custom-event-bubbling-and-extraneous-properties-in-the-local-component-tree/)

## Example: A Reusable Button

Let's create a simple, reusable button component that lives in `src/shared/ui/button`.

**Presentational Button Component:**
```typescript
// src/shared/ui/button/button.component.ts
import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-button',
  template: `
    <button [disabled]="disabled" (click)="handleClick.emit()">
      {{ label }}
    </button>
  `,
  // ... styles
})
export class ButtonComponent {
  @Input() label: string;
  @Input() disabled: boolean = false;
  @Output() handleClick = new EventEmitter<void>();
}
```
This button knows nothing about what it's used for. It just knows how to display a label and that it can be disabled. When clicked, it emits an event.

## Example: Using the Button in a Feature

Now, let's use this button in a "smart" container component within a feature.

**Container Component (e.g., a Login Form):**
```typescript
// src/features/user-login/user-login.component.ts
import { Component } from '@angular/core';
import { AuthService } from '../../entities/user/model/auth.service';

@Component({
  selector: 'app-user-login',
  template: `
    ... (form fields)
    <app-button
      label="Login"
      [disabled]="loginForm.invalid || isLoading"
      (handleClick)="onLogin()">
    </app-button>
  `
})
export class UserLoginComponent {
  // ... form logic
  isLoading = false;

  constructor(private authService: AuthService) {}

  onLogin() {
    this.isLoading = true;
    this.authService.login(this.loginForm.value).subscribe({
      next: () => { /* handle success */ },
      error: () => { /* handle error */ },
      complete: () => { this.isLoading = false; }
    });
  }
}
```
The `UserLoginComponent` is the container. It knows about the `AuthService`, manages the `isLoading` state, and defines what happens when the button is clicked. It passes the `label` and `disabled` state down to the presentational `app-button` and listens for its `handleClick` event.

## Benefits of this Pattern

-   **Clear Separation of Concerns:** It's easy to distinguish between UI and business logic.
-   **Improved Reusability:** Presentational components can be reused across the entire application, leading to a more consistent UI and less duplicated code.
-   **Easier Testing:**
    -   Presentational components can be tested in isolation, often with simple snapshot tests or by checking that they render correctly given a set of inputs.
    -   Container components can be tested by mocking their service dependencies and checking that they call the correct methods.
-   **Better for Collaboration:** UI/UX developers can focus on building the `shared/ui` library without needing to understand the application's complex business logic.

By consistently applying this pattern, especially for your `shared/ui` layer, you create a robust and scalable foundation for your Angular application.
- **Resource:** [Designing Angular architecture - Container-Presentation pattern](https://angular.love/designing-angular-architecture-container-presentation-pattern/)

---

## ✅ Verifiable Outcome

After completing this lesson, you can verify your understanding by building and testing the `ButtonComponent` and `UserLoginComponent` example.

1.  **Create the `ButtonComponent`:**
    -   Create the presentational `ButtonComponent` in `src/shared/ui/button/`.
    -   Verify that it has no injected services in its constructor.

2.  **Create the `UserLoginComponent`:**
    -   Create the container `UserLoginComponent` in `src/features/user-login/`.
    -   Create a mock `AuthService` that it can inject.
    -   In the template, use the `<app-button>` component.

3.  **Run the Application:**
    -   Display the `UserLoginComponent` in your `app.component.html`.
    -   Run `ng serve`.
    -   **Expected Result:** You should see the login form with the reusable button. Clicking the button should trigger the `onLogin` method in the `UserLoginComponent` and log a message to the console, proving that the `@Output()` event binding is working correctly. The button's disabled state should also correctly reflect the form's state.