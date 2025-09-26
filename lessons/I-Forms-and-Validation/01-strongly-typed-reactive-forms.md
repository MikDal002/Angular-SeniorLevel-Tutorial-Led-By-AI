# Lesson 1: Strongly-Typed Reactive Forms

For many years, Angular's reactive forms were not type-safe. The value of `form.value` was `any`, and accessing controls required string-based lookups (`form.get('name')`), offering no protection against typos or refactoring errors.

Starting in Angular v14, **Strictly Typed Reactive Forms** were introduced, providing excellent type safety and editor autocompletion throughout the forms API.

- **Resource:** [Official Angular Guide: Strictly typed reactive forms](https://angular.io/guide/forms/typed-forms)
- **Resource:** [Strongly Typed Reactive Forms in Angular](https://angular.love/strongly-typed-reactive-forms-in-angular/)

## The Core Concepts

The key to typed forms is providing generic types to the core reactive forms classes: `FormControl`, `FormGroup`, and `FormArray`.

### `FormControl<T>`

You can specify the type of value a control will hold.

```typescript
// This control is typed to always hold a string or null.
const nameControl = new FormControl<string | null>(null);
```

### `FormGroup<T>`

For a `FormGroup`, you define an interface that describes the shape of the form's controls.

```typescript
import { FormGroup, FormControl } from '@angular/forms';

// 1. Define the shape of the form's controls.
interface LoginForm {
  email: FormControl<string | null>;
  password: FormControl<string | null>;
}

// 2. Create the FormGroup with the interface as its generic type.
const loginForm = new FormGroup<LoginForm>({
  email: new FormControl('', { validators: [Validators.required, Validators.email] }),
  password: new FormControl('', { validators: [Validators.required] }),
});

// Now, this is type-safe!
const emailValue: string | null = loginForm.value.email;
```

## Using `FormBuilder` and `NonNullableFormBuilder`

Using the `FormBuilder` service is the recommended way to create complex forms. For typed forms, you should inject `NonNullableFormBuilder` to ensure that the form's value doesn't contain `null` for controls that are initialized with a non-nullable value. This is especially useful for forms where all fields are required.

```typescript
import { Component, inject } from '@angular/core';
import { NonNullableFormBuilder, Validators } from '@angular/forms';

@Component({ /* ... */ })
export class LoginComponent {
  private fb = inject(NonNullableFormBuilder);

  // The type is inferred automatically from the group definition.
  loginForm = this.fb.group({
    // Because we provide a non-nullable initial value (''), the control's
    // type is FormControl<string>, not FormControl<string | null>.
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required]],
    rememberMe: [false, [Validators.required]],
  });
}
```
With `NonNullableFormBuilder`, the type of `loginForm.value` will not contain `null` for any of the properties, reflecting the non-nullable initial values.

## `value` vs. `getRawValue()`

A key aspect of typed forms is how they handle disabled controls.

-   `form.value`: The value of a `FormGroup` is a **partial** object. It will **exclude** the values of any disabled controls. This is the default behavior because disabled controls don't typically submit their values in a native HTML form.
-   `form.getRawValue()`: This method returns the **full** value of the form, including the values of any disabled controls.

**Example:**
```typescript
const form = this.fb.group({
  name: [''],
  id: [{ value: '123', disabled: true }]
});

// `form.value` will be { name: '' }
// The disabled `id` control is excluded.
console.log(form.value);

// `form.getRawValue()` will be { name: '', id: '123' }
// It includes all controls, regardless of their disabled state.
console.log(form.getRawValue());
```

**Rule of thumb:** When you need the complete data model of the form to send to an API, always use `getRawValue()`.

## Other Typed Form Classes

-   **`FormArray<T>`**: Used for a collection of controls where `T` is the type of control in the array (e.g., `FormArray<FormControl<string>>`).
-   **`FormRecord<T>`**: Used when you have a group of controls where the keys are not known ahead of time (like a dynamic form). `T` is the type of control (e.g., `FormRecord<FormControl<boolean>>` for a dynamic list of checkboxes).

By embracing strictly typed reactive forms, you can eliminate a whole class of common bugs, improve the maintainability of your code, and benefit from a much better developer experience with robust type-checking and autocompletion in your IDE.