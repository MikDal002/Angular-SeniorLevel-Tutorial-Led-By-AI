# Lesson 1: Component Store Basics

Not all state needs to be global. In fact, most state is specific to a particular component or feature. Placing this "local" state in a global NgRx Store can add unnecessary complexity and boilerplate.

**NgRx Component Store** is a standalone library designed to manage local/component state. It provides a structured, reactive, and self-contained way to handle state logic that lives and dies with a component.

- **Resource:** [Component Store 101 — Main concepts by HeroDevs](https://www.herodevs.com/blog-posts/component-store-101----main-concepts-and-ngrx-store-interactions)
- **Video Resource:** [Learn NgRx Component Store by MonsterLessons Academy](https://www.youtube.com/watch?v=Zl45RERUN0U)

## Core Concepts

A Component Store is an injectable class that you provide directly in your component's `providers` array. It manages its own state, which is automatically cleaned up when the component is destroyed.

It has three main building blocks:
1.  **State:** The data being stored.
2.  **Selectors:** For getting "slices" of the state.
3.  **Updaters and Effects:** For modifying the state.

## Setting Up a Component Store

Let's build a simple store to manage a list of items for a feature component.

### 1. Define the State Interface

First, define the shape of your local state.

```typescript
// items.store.ts
export interface ItemsState {
  items: string[];
  isLoading: boolean;
  error: string | null;
}
```

### 2. Create the Store

Create an injectable class that extends `ComponentStore` and pass your state interface to it. Initialize the state in the constructor by calling `super()`.

```typescript
// items.store.ts
import { Injectable } from '@angular/core';
import { ComponentStore } from '@ngrx/component-store';

// ... (ItemsState interface)

@Injectable()
export class ItemsStore extends ComponentStore<ItemsState> {
  constructor() {
    // Initialize the state
    super({
      items: [],
      isLoading: false,
      error: null,
    });
  }
}
```

### 3. Provide the Store

In your feature component, provide the store in the `providers` array. This ensures that a new instance of the store is created for each instance of the component, and it will be destroyed automatically.

```typescript
// my-feature.component.ts
@Component({
  selector: 'app-my-feature',
  // ...
  providers: [ItemsStore], // Provide the store here
})
export class MyFeatureComponent {
  constructor(private readonly store: ItemsStore) {}
}
```

## Reading State with Selectors

Selectors are observables that emit a slice of the state. You create them using the `this.select()` method.

-   `this.select(state => state.someSlice)`: Selects a piece of the state.
-   Selectors are automatically memoized, meaning they only re-compute if the underlying state they depend on has changed.

```typescript
// items.store.ts
export class ItemsStore extends ComponentStore<ItemsState> {
  // ... constructor

  // --- SELECTORS ---
  readonly items$ = this.select(state => state.items);
  readonly isLoading$ = this.select(state => state.isLoading);
  readonly error$ = this.select(state => state.error);

  // You can combine selectors to create a view model
  readonly vm$ = this.select(
    this.items$,
    this.isLoading$,
    (items, isLoading) => ({ items, isLoading })
  );
}
```

In your component, you can then subscribe to these selectors (usually with `| async` or `toSignal`).

```html
<!-- my-feature.component.html -->
<ng-container *ngIf="store.vm$ | async as vm">
  <div *ngIf="vm.isLoading">Loading...</div>
  <ul>
    <li *ngFor="let item of vm.items">{{ item }}</li>
  </ul>
</ng-container>
```

## Modifying State with Updaters

To change the state, you create **updaters**. An updater is a method that takes some input and returns a new state object. You create them using `this.updater()`.

-   An updater is a function that receives the current state and the value passed to the updater method.
-   It must return a new state object, promoting immutability.

```typescript
// items.store.ts
export class ItemsStore extends ComponentStore<ItemsState> {
  // ... selectors

  // --- UPDATERS ---
  readonly addItem = this.updater((state, item: string) => ({
    ...state,
    items: [...state.items, item],
  }));

  readonly setLoading = this.updater((state, isLoading: boolean) => ({
    ...state,
    isLoading,
  }));
}
```

You can then call these updaters like regular methods from your component: `this.store.addItem('New Item');`.

## Handling Side Effects with Effects

**Effects** are used to handle side effects, like making HTTP requests. An effect takes an observable stream and performs some action, often calling an updater in the process. You create them using `this.effect()`.

-   `this.effect()` takes a function that accepts an observable of a generic type (`Observable<T>`).
-   Inside this function, you build an RxJS pipeline to handle the side effect.

```typescript
// items.store.ts
import { tap, switchMap, catchError } from 'rxjs/operators';
import { of } from 'rxjs';

export class ItemsStore extends ComponentStore<ItemsState> {
  // ... constructor, selectors, updaters

  // --- EFFECTS ---
  readonly getItems = this.effect<void>(trigger$ => {
    return trigger$.pipe(
      tap(() => this.setLoading(true)), // Use an updater to change state
      switchMap(() => this.itemsService.getItems().pipe(
        tapResponse(
          (items) => this.addItems(items)), // `addItems` is another updater
          (error) => this.setError(error)), // `setError` is another updater
        )
      )
    );
  });
}
```
*Note: The `tapResponse` operator from `@ngrx/component-store` is a convenient utility for handling the success and error paths of an observable inside an effect.*

You can then trigger the effect from your component: `this.store.getItems();`.

---

## ✅ Verifiable Outcome

After completing this lesson, you can verify your understanding by building the `ItemsStore` and a component to consume it.

1.  **Build the Store and Component:**
    -   Create the `ItemsStore` as described in the lesson, including the state, selectors, updaters, and the `getItems` effect.
    -   Create a mock `ItemsService` that the effect can call. It should return an `Observable` of a string array (e.g., `of(['First Item', 'Second Item']).pipe(delay(1000))`).
    -   Create the `MyFeatureComponent` that provides and injects the store.
    -   In the component's template, use the `vm$` selector with an `async` pipe to display the loading state and the list of items.
    -   Add a button to trigger the `store.getItems()` effect.
    -   Add an input field and a button to trigger the `store.addItem()` updater.

2.  **Test the Effect:**
    -   Run the application. The list should be empty.
    -   Click the "Get Items" button.
    -   **Expected Result:** You should immediately see the "Loading..." message appear. After a 1-second delay, the loading message should disappear, and the list of items from your mock service should be displayed.

3.  **Test the Updater:**
    -   Type a new item name into the input field.
    -   Click the "Add Item" button.
    -   **Expected Result:** The new item should instantly appear at the end of the list in the UI, demonstrating that the updater has modified the state correctly.