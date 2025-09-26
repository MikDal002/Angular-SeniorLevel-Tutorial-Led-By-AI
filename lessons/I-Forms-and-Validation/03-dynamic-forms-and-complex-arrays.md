# Lesson 3: Dynamic Forms and Complex Arrays

Many real-world forms are not static. A user might need to add multiple phone numbers, manage a list of invoice line items, or add skills to their profile. These "dynamic" forms require a way to add and remove form controls on the fly.

Angular's reactive forms handle this scenario with the **`FormArray`** class. A `FormArray` is a way to manage a collection of `FormControl`, `FormGroup`, or even other `FormArray` instances.

- **Resource:** [Angular FormArray Example](https://www.tektutorialshub.com/angular/angular-formarray-example-in-reactive-forms/)

## The Scenario: An Invoice Form

Let's build a form to create an invoice. The invoice will have a customer name, and a dynamic list of line items. Each line item will have a description, quantity, and price.

## 1. Setting up the Form

We'll create a main `FormGroup` for the invoice, which will contain a `FormArray` for the `lineItems`.

```typescript
// invoice.component.ts
import { Component, inject } from '@angular/core';
import { FormArray, FormGroup, NonNullableFormBuilder, Validators } from '@angular/forms';

@Component({ /* ... */ })
export class InvoiceComponent {
  private fb = inject(NonNullableFormBuilder);

  invoiceForm = this.fb.group({
    customerName: ['', Validators.required],
    // A FormArray to hold our dynamic list of line items.
    lineItems: this.fb.array([
      // We can start with one line item by default.
      this.createLineItemGroup()
    ])
  });

  // A helper method to create a new FormGroup for a single line item.
  // This ensures consistency and makes adding new items easy.
  private createLineItemGroup(): FormGroup {
    return this.fb.group({
      description: ['', Validators.required],
      quantity: [1, [Validators.required, Validators.min(1)]],
      price: [0, [Validators.required, Validators.min(0)]]
    });
  }
}
```

## 2. Adding and Removing Controls

We need methods on our component to programmatically add and remove `FormGroup` instances from our `FormArray`.

```typescript
// invoice.component.ts (continued)

// A getter for easy access to the FormArray in the template.
get lineItems(): FormArray {
  return this.invoiceForm.get('lineItems') as FormArray;
}

// Method to add a new line item.
addLineItem(): void {
  // We push a new FormGroup instance created by our helper method.
  this.lineItems.push(this.createLineItemGroup());
}

// Method to remove a line item at a specific index.
removeLineItem(index: number): void {
  this.lineItems.removeAt(index);
}
```

## 3. Binding to the Template

Now we connect our `FormGroup` and `FormArray` to the HTML template.

-   Use `[formGroup]` to bind the main form.
-   Use the `formArrayName` directive to bind the `FormArray`.
-   Use `*ngFor` to loop over the `controls` of the `FormArray`.
-   Inside the loop, use the `[formGroupName]` directive to bind each `FormGroup` in the array to its corresponding index.

```html
<!-- invoice.component.html -->
<form [formGroup]="invoiceForm" (ngSubmit)="onSubmit()">
  <!-- Customer Name Control -->
  <div>
    <label for="customerName">Customer Name:</label>
    <input id="customerName" formControlName="customerName">
  </div>

  <hr>

  <!-- Line Items FormArray -->
  <h3>Line Items</h3>
  <div formArrayName="lineItems">
    <!-- Loop over each FormGroup in the FormArray -->
    <div *ngFor="let lineItem of lineItems.controls; let i = index" [formGroupName]="i">
      <input formControlName="description" placeholder="Description">
      <input formControlName="quantity" type="number" placeholder="Quantity">
      <input formControlName="price" type="number" placeholder="Price">

      <!-- Button to remove this specific line item -->
      <button type="button" (click)="removeLineItem(i)" [disabled]="lineItems.length <= 1">
        Remove
      </button>
    </div>
  </div>

  <!-- Button to add a new line item -->
  <button type="button" (click)="addLineItem()">Add Line Item</button>

  <hr>

  <button type="submit" [disabled]="invoiceForm.invalid">Create Invoice</button>
</form>

<!-- For debugging -->
<pre>{{ invoiceForm.getRawValue() | json }}</pre>
```

### Key Template Bindings

-   **`formArrayName="lineItems"`**: This tells Angular that the `div` is a container for a `FormArray` named `lineItems` within the parent `invoiceForm`.
-   **`*ngFor="let lineItem of lineItems.controls; let i = index"`**: We iterate over the `controls` property of our `FormArray`. Each `lineItem` in this loop is a `FormGroup` instance.
-   **`[formGroupName]="i"`**: This is the crucial part. It tells Angular that the elements inside this `div` belong to the `FormGroup` at index `i` within the `lineItems` `FormArray`.

`FormArray` is a powerful tool for building complex, dynamic forms in Angular. By creating helper methods to manage the array and using the correct template directives, you can create intuitive user experiences for managing lists of data.