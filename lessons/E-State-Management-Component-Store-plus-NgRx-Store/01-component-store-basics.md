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

Component Store provides a powerful and lightweight pattern for managing state within the boundaries of a feature, giving you the structure of NgRx without the global overhead.