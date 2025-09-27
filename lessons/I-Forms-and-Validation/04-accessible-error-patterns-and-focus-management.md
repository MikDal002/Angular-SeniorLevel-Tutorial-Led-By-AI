# Lesson 4: Accessible Error Patterns and Focus Management

Creating a form that is technically valid is only half the battle. A truly usable form provides clear, accessible feedback when things go wrong and helps guide the user to a successful submission. This lesson covers two critical aspects of an accessible form experience: linking error messages to inputs and managing focus on submission.

## Don't Disable the Submit Button

A common but problematic pattern is to disable the submit button until the form is valid. This can be confusing for users, especially those using screen readers. They may not understand *why* the button is disabled.

A better approach is to **always leave the submit button enabled**. When the user clicks it and the form is invalid, you can then present the errors and programmatically move the focus to the first invalid field, guiding them directly to what needs to be fixed.

- **Resource:** [A Guide To Accessible Form Validation](https://www.smashingmagazine.com/2023/02/guide-accessible-form-validation/)

## Linking Errors to Inputs with `aria-describedby`

When an error message appears, sighted users can visually associate it with the correct input field. Screen reader users need a programmatic connection. The `aria-describedby` attribute is the standard way to create this link.

It works by pointing to the `id` of the element that contains the error message.

### The Pattern

1.  Give your error message element a unique `id`. A good pattern is `[controlName]-error`.
2.  Add the `aria-describedby` attribute to your `input` element, binding it to the error message's `id` only when the error is present.
3.  Add `aria-invalid="true"` to the input when it's invalid to signal its state to assistive technologies.

**Example:**
```html
<div class="form-field">
  <label for="email">Email Address</label>
  <input
    id="email"
    formControlName="email"
    [attr.aria-describedby]="email.invalid && email.touched ? 'email-error' : null"
    [attr.aria-invalid]="email.invalid && email.touched"
  >

  <!-- The error message container -->
  <div
    *ngIf="email.invalid && email.touched"
    class="error-message"
    id="email-error"
    role="alert"
  >
    <div *ngIf="email.errors?.['required']">
      Email address is required.
    </div>
    <div *ngIf="email.errors?.['email']">
      Please enter a valid email address.
    </div>
  </div>
</div>
```
*(This assumes you have a getter `get email() { return this.form.get('email'); }` in your component for easier access).*

Now, when a screen reader user focuses on the invalid email input, it will announce the input's label and then read the content of the linked error message, providing immediate and clear feedback.

## Managing Focus on Submission

For long forms, the first error might be off-screen. When a user clicks "Submit" and nothing seems to happen, it's a frustrating experience. The best practice is to programmatically move the browser's focus to the first invalid form control.

- **Resource:** [Focus First Invalid Input with Angular Forms by Cory Rylan](https://coryrylan.com/blog/focus-first-invalid-input-with-angular-forms)

### The Pattern

1.  In your `onSubmit` method, first check if the form is invalid.
2.  If it is, mark all controls as `touched` to ensure all error messages are displayed.
3.  Iterate through the form's controls in the order they appear in the DOM.
4.  For the first invalid control you find, query the DOM for its element and call `.focus()`.

**Example:**
```typescript
// registration.component.ts
import { Component, ElementRef, inject } from '@angular/core';
import { FormGroup, NonNullableFormBuilder, Validators } from '@angular/forms';

@Component({ /* ... */ })
export class RegistrationComponent {
  private fb = inject(NonNullableFormBuilder);
  private elementRef = inject(ElementRef); // Inject ElementRef to access the component's host element

  form = this.fb.group({
    name: ['', Validators.required],
    email: ['', [Validators.required, Validators.email]],
    password: ['', Validators.required],
  });

  onSubmit(): void {
    if (this.form.invalid) {
      // Mark all fields as touched to show errors
      this.form.markAllAsTouched();

      // Find and focus the first invalid control
      this.focusFirstInvalidControl();
      return;
    }

    // ... handle successful submission
    console.log('Form Submitted!', this.form.getRawValue());
  }

  private focusFirstInvalidControl(): void {
    // Get the keys of the form controls in order
    const controls = Object.keys(this.form.controls);
    // Find the first invalid control
    const firstInvalidControl = controls.find(key => this.form.get(key)?.invalid);

    if (firstInvalidControl) {
      // Find the corresponding DOM element using its formControlName
      const invalidElement = this.elementRef.nativeElement.querySelector(
        `[formControlName="${firstInvalidControl}"]`
      );
      if (invalidElement) {
        // Programmatically focus the element
        invalidElement.focus();
      }
    }
  }
}
```

By combining accessible error messages with programmatic focus management, you create a form that not only validates data correctly but also provides a clear, helpful, and non-frustrating experience for all users, especially those relying on assistive technologies.