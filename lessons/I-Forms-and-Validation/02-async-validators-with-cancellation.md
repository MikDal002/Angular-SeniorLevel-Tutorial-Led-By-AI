# Lesson 2: Async Validators with Cancellation

Synchronous validators are great for checking a field's format (e.g., `Validators.required`, `Validators.email`), but sometimes you need to validate a value against a backend service. For example: "Is this username already taken?"

This requires an **asynchronous validator**. A well-built async validator is crucial for good user experience and for preventing invalid data from being submitted. However, a naive implementation can lead to performance issues and race conditions. This lesson covers how to build a robust async validator that includes debouncing and cancellation.

- **Resource:** [Async Validators in Angular: Best Practices and Example](https://medium.com/@ignatovich.dm/async-validators-in-angular-why-they-matter-best-practices-and-example-implementation-fdee42005674)

## The `AsyncValidatorFn` Interface

An async validator is a function that matches the `AsyncValidatorFn` interface. It takes a form control as an argument and returns a `Promise` or `Observable` that emits:
-   `null` if the control's value is **valid**.
-   A `ValidationErrors` object (e.g., `{ usernameTaken: true }`) if the value is **invalid**.

## The Problem: Race Conditions and Excessive API Calls

A naive async validator might look like this:

```typescript
// NAIVE - DO NOT USE
function naiveUsernameValidator(userService: UserService): AsyncValidatorFn {
  return (control: AbstractControl): Observable<ValidationErrors | null> => {
    // This makes an API call on EVERY keystroke!
    return userService.isUsernameTaken(control.value).pipe(
      map(isTaken => (isTaken ? { usernameTaken: true } : null))
    );
  };
}
```

This implementation has two major flaws:
1.  **Excessive API Calls:** It sends a request to the server on every single keystroke, which can overload your backend and waste resources.
2.  **Race Conditions:** If the user types "myuser" and then quickly deletes a character to "myuse", two requests are sent. If the "myuser" request (which might be valid) returns *after* the "myuse" request (which might be invalid), the validator will be left in an incorrect state.

## The Solution: A Debounced, Cancelling Validator

The solution is to treat the control's `valueChanges` as a stream and apply the same RxJS patterns we use for other UI events.

1.  **`debounceTime`**: Wait for the user to stop typing before sending a request.
2.  **`distinctUntilChanged`**: Only send a request if the value has actually changed.
3.  **`switchMap`**: Cancel the previous validation request as soon as a new value comes in. This is the key to preventing race conditions.
4.  **`catchError`**: Handle potential HTTP errors gracefully so they don't break the form.

### Creating the Validator Service

It's best practice to create an injectable service that provides your validator function. This allows you to inject other services (like a `UserService`) into it.

```typescript
// username-validator.service.ts
import { Injectable, inject } from '@angular/core';
import { AbstractControl, AsyncValidator, ValidationErrors } from '@angular/forms';
import { Observable, of } from 'rxjs';
import { map, debounceTime, distinctUntilChanged, switchMap, catchError, first } from 'rxjs/operators';
import { UserService } from './user.service'; // Your service to check the API

@Injectable({ providedIn: 'root' })
export class UsernameValidator implements AsyncValidator {
  private userService = inject(UserService);

  validate(control: AbstractControl): Observable<ValidationErrors | null> {
    return control.valueChanges.pipe(
      // 1. Wait for 300ms pause in typing
      debounceTime(300),
      // 2. Only validate if the value has changed
      distinctUntilChanged(),
      // 3. Cancel previous request and switch to a new one
      switchMap(value => this.userService.isUsernameTaken(value).pipe(
        // 4. Map the boolean response to the expected validator format
        map(isTaken => (isTaken ? { usernameTaken: true } : null)),
        // 5. Handle any API errors gracefully
        catchError(() => of(null)) // On error, assume valid to not block the user
      )),
      // 6. We only need the first emission from this chain
      first()
    );
  }
}
```
*Note: We use the `first()` operator because an async validator should emit once and then complete. `valueChanges` is a long-lived stream, but the validator only needs the first valid emission from our pipeline.*

### Applying the Validator

Now, you can inject your validator service into your component and apply it to the form control.

```typescript
// registration.component.ts
import { Component, inject } from '@angular/core';
import { NonNullableFormBuilder, Validators } from '@angular/forms';
import { UsernameValidator } from './username-validator.service';

@Component({ /* ... */ })
export class RegistrationComponent {
  private fb = inject(NonNullableFormBuilder);
  // Inject the validator service
  private usernameValidator = inject(UsernameValidator);

  form = this.fb.group({
    username: ['',
      [Validators.required, Validators.minLength(3)], // Sync validators
      [this.usernameValidator.validate.bind(this.usernameValidator)] // Async validators
    ],
    // ... other controls
  });
}
```

This approach creates a highly efficient and robust async validator that provides a great user experience by giving feedback only when necessary, and is safe from race conditions and unexpected errors.