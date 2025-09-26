# Lesson 2: Component Store Pitfalls

NgRx Component Store is a powerful tool, but like any tool, it can be misused. Understanding common pitfalls will help you write more robust, predictable, and bug-free state management logic.

This lesson covers three common pitfalls: stale snapshots, racing effects, and nested mutations.

## Pitfall 1: Stale Snapshots (Imperative vs. Reactive)

A "stale snapshot" occurs when you read the store's state imperatively at a single point in time, assuming it's the most current version. This can lead to bugs where your logic is acting on outdated information.

-   **The Problem:** Using `this.get()` to fetch the current state value. While `get()` has its uses (e.g., in guards or resolvers), it's dangerous inside component logic because it's not reactive.

**BAD - Stale Snapshot:**
```typescript
// in a component method
onAddItem(newItem: string) {
  const currentState = this.store.get(); // Gets the state *right now*
  if (currentState.items.includes(newItem)) {
    // RACE CONDITION: Another operation could have added this item
    // right after we called .get(), but before we check. This code
    // would then add a duplicate.
    return;
  }
  this.store.addItem(newItem);
}
```

-   **The Solution:** Always use selectors (`this.select()`) for reading state and base your logic on reactive streams. This ensures your logic always has the most up-to-date information.

**GOOD - Reactive Logic:**
You can handle this logic inside an `effect` in your store, which is the preferred way.

```typescript
// in your component store
readonly addItem = this.effect((item$: Observable<string>) => {
  return item$.pipe(
    // Use withLatestFrom to get the latest state from a selector
    withLatestFrom(this.items$),
    filter(([newItem, existingItems]) => !existingItems.includes(newItem)),
    tap(([newItem]) => {
      // The updater now only runs if the item is not a duplicate.
      this.updater(state => ({ ...state, items: [...state.items, newItem] }))();
    })
  );
});
```
By using a selector with `withLatestFrom`, you guarantee you are always checking against the most recent state at the moment the effect runs.

## Pitfall 2: Racing Effects

A race condition in an effect occurs when an effect is triggered multiple times in quick succession, and the operations (e.g., HTTP requests) complete in an unpredictable order.

-   **The Problem:** Using the wrong flattening operator in an effect. `mergeMap` is a common culprit here. If a user clicks a "save" button twice, `mergeMap` will fire two parallel save requests, which could lead to data corruption.

**BAD - Race Condition with `mergeMap`:**
```typescript
// in your component store
readonly saveItem = this.effect((item$: Observable<Item>) => {
  return item$.pipe(
    // If triggered twice, two save requests run in parallel.
    // The second one might finish before the first!
    mergeMap(item => this.apiService.save(item).pipe(/* ... */))
  );
});
```

-   **The Solution:** Choose the right concurrency operator for the job. The same principles from the "Concurrency Semantics" lesson apply directly to Component Store effects.
    -   `concatMap`: Queues the operations. Guarantees order. Good for saves, updates, deletes.
    -   `switchMap`: Cancels the previous operation. Good for search-as-you-type.
    -   `exhaustMap`: Ignores new triggers while an operation is in flight. Excellent for preventing double-clicks on submit buttons.

**GOOD - `exhaustMap` to prevent double-submits:**
```typescript
// in your component store
readonly saveItem = this.effect((item$: Observable<Item>) => {
  return item$.pipe(
    // Ignores subsequent triggers until the save is complete.
    exhaustMap(item => this.apiService.save(item).pipe(
      tapResponse(
        (response) => this.setSaveSuccess(response),
        (error) => this.setSaveError(error)
      )
    ))
  );
});
```
- **Resource:** [When to Use concatMap, mergeMap, switchMap or exhaustMap](https://danywalls.com/when-to-use-concatmap-mergemap-switchmap-and-exhaustmap-operators-in-building-a-crud-with-ngrx)

## Pitfall 3: Nested Mutations

State in NgRx (both global and Component Store) should be treated as immutable. Directly mutating a nested object or array within your state is a common bug that can break change detection and lead to an unpredictable UI.

-   **The Problem:** Using methods like `.push()` on an array in the state or directly setting a property on a nested object.

**BAD - Direct Mutation:**
```typescript
// in an updater
this.updater(state => {
  // THIS IS BAD! It mutates the existing state.
  state.config.userPreferences.push('new-preference');
  return state;
})
```

-   **The Solution:** Always return a *new* state object, creating new copies of any nested objects or arrays that you are changing. The spread operator (`...`) is your best friend here.

**GOOD - Immutable Update:**
```typescript
// in an updater
this.updater(state => ({
  ...state, // Copy top-level properties
  config: {
    ...state.config, // Copy nested config properties
    userPreferences: [
      ...state.config.userPreferences, // Copy existing preferences
      'new-preference' // Add the new one
    ]
  }
}))
```
For deeply nested state, this can become verbose. Libraries like `immer` (or `ngrx-immer`) can simplify this process, but understanding the manual spread-operator pattern is fundamental.

By avoiding these common pitfalls, you can leverage the full power of Component Store to create state management logic that is safe, predictable, and easy to debug.