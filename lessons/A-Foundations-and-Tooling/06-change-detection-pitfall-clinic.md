# Lesson 6: Change Detection Pitfall Clinic

One of the most common sources of bugs and performance issues in Angular is misunderstanding how `OnPush` change detection works, especially when dealing with object and array mutations. This lesson will demonstrate a classic "stale view" bug and show you how to fix it using three powerful techniques: immutable updates, signals, and `trackBy`.

## The Problem: `OnPush` and Mutation

The `OnPush` change detection strategy is a powerful optimization technique. When a component is set to `OnPush`, Angular will only run change detection on it if:
1.  One of its `@Input()` properties receives a new reference.
2.  An event handler in the component's template is triggered.
3.  Change detection is manually triggered (e.g., with `ChangeDetectorRef.markForCheck()`).
4.  An observable subscribed to with the `async` pipe emits a new value.
5.  A `signal` that is read in the template is updated.

The key here is **new reference**. If you have an `@Input()` that is an object or an array, and you simply change a property of that object or add an item to the array, the reference to the object or array itself does not change. As a result, Angular will not update the component's view, leading to a stale UI.

### Reproducing the Bug

Let's imagine a parent component that passes a list of items to a child component.

**Parent Component:**
```typescript
// parent.component.ts
@Component({
  selector: 'app-parent',
  template: `
    <button (click)="addItem()">Add Item</button>
    <app-child [items]="items"></app-child>
  `
})
export class ParentComponent {
  items = [{ id: 1, name: 'First Item' }];

  addItem() {
    // This is a mutation!
    this.items.push({ id: 2, name: 'Second Item' });
  }
}
```

**Child Component:**
```typescript
// child.component.ts
@Component({
  selector: 'app-child',
  template: `
    <ul>
      <li *ngFor="let item of items">{{ item.name }}</li>
    </ul>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ChildComponent {
  @Input() items: { id: number; name: string }[];
}
```

When you click the "Add Item" button, nothing happens in the UI. This is because we mutated the `items` array by using `.push()`. The reference to the `items` array did not change, so the `OnPush` child component is not updated.

- **Resource:** [Angular OnPush Change Detection and Component Design - Avoid Common Pitfalls](https://blog.angular-university.io/onpush-change-detection-how-it-works/)

## Solution 1: Immutable Updates

The most direct way to fix this is to create a new array with the new item, instead of mutating the existing one.

- **Action:** Modify the `addItem` method in the parent component to use an immutable update.
  ```typescript
  // parent.component.ts
  addItem() {
    // This creates a new array reference.
    this.items = [...this.items, { id: 2, name: 'Second Item' }];
  }
  ```
Now, when `addItem` is called, a new array is created. This new reference is passed to the child component's `@Input()`, triggering change detection and updating the view.

- **Resource:** [Deep dive into the OnPush change detection strategy in Angular](https://angular.love/deep-dive-into-the-onpush-change-detection-strategy-in-angular/)

## Solution 2: Using Signals

Angular Signals provide a more modern and elegant solution to this problem. When a signal's value changes, Angular knows precisely which components need to be updated, even with `OnPush`.

- **Action:** Refactor the parent and child components to use signals.

**Parent Component with Signals:**
```typescript
// parent.component.ts
import { signal, Component } from '@angular/core';

@Component({
  selector: 'app-parent',
  template: `
    <button (click)="addItem()">Add Item</button>
    <app-child [items]="items()"></app-child>
  `
})
export class ParentComponent {
  items = signal([{ id: 1, name: 'First Item' }]);

  addItem() {
    // Use the .update() method of the signal to immutably update the value.
    this.items.update(currentItems => [...currentItems, { id: 2, name: 'Second Item' }]);
  }
}
```
Notice that we are still using an immutable update inside the signal's `update` function. While you *could* mutate the array and then call `set` with the same array reference, this is an anti-pattern. Immutability is the recommended approach with signals as well.

- **Resource:** [Angular Signals Overview](https://angular.io/guide/signals)

## Solution 3: `trackBy` for Performance

Even with immutable updates, there's another performance pitfall. When the `items` array is replaced, `*ngFor` will, by default, tear down all of the `<li>` elements from the DOM and recreate them. For large lists, this can be very inefficient.

The `trackBy` function tells `*ngFor` how to track each item in the list. If the identity of an item hasn't changed, `*ngFor` will reuse the existing DOM element.

- **Action:** Add a `trackBy` function to the child component.

**Child Component with `trackBy`:**
```typescript
// child.component.ts
@Component({
  selector: 'app-child',
  template: `
    <ul>
      <li *ngFor="let item of items; trackBy: trackById">{{ item.name }}</li>
    </ul>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ChildComponent {
  @Input() items: { id: number; name:string }[];

  trackById(index: number, item: { id: number; name: string }): number {
    return item.id;
  }
}
```
Now, when the `items` array is updated, `*ngFor` will use the `trackById` function to see which items are new. It will only create a new `<li>` for the new item, and it will leave the existing ones untouched, resulting in a significant performance improvement for large lists.

- **Resource:** [Optimizing `*ngFor` with `trackBy`](https://medium.com/@ausaf.cs/angular-change-detection-how-it-works-and-how-to-optimize-it-77fb189d2282)

---

## ✅ Verifiable Outcome

To verify the concepts in this lesson, you can build the "Broken" version of the `ParentComponent` and `ChildComponent` and observe the incorrect behavior.

1.  **Observe the Mutation Bug:**
    -   Create the two components as described in the "Reproducing the Bug" section.
    -   Run the application and click the "Add Item" button.
    -   **Expected Result:** You will see nothing happen in the UI. The list will not update, demonstrating that mutating the `@Input` array does not trigger `OnPush` change detection.

2.  **Verify the Immutable Update Fix:**
    -   Modify the `addItem` method in the `ParentComponent` to use the immutable update pattern (`this.items = [...this.items, newItem];`).
    -   Run the application again and click the "Add Item" button.
    -   **Expected Result:** The new item should now appear correctly in the list, demonstrating that providing a new array reference triggers the change detection.

3.  **Verify `trackBy` (Advanced):**
    -   Add the `trackBy` function to the `ChildComponent` and `*ngFor`.
    -   Open your browser's Developer Tools and inspect the `<ul>` element.
    -   Click the "Add Item" button.
    -   **Expected Result:** Observe the DOM updates in the DevTools. You should see that only a single new `<li>` element is added to the DOM. The existing `<li>` element for the first item is not touched or re-rendered, proving that `trackBy` is optimizing the DOM updates.