# Lesson 4: Entity Adapter and Memoized Selectors

Managing collections of data (or "entities") is a fundamental task in state management. Writing reducers to handle basic Create, Read, Update, and Delete (CRUD) operations for each new entity type can be repetitive and error-prone.

**@ngrx/entity** is a library that provides a standardized, efficient way to manage entity collections, while **memoized selectors** ensure that we can query this data performantly.

## The Problem: Boilerplate Reducers

Imagine managing a collection of `Product` models. Your state might look like this:

```typescript
export interface ProductsState {
  products: Product[];
  isLoading: boolean;
  error: any;
}
```

You would need to write reducer logic for `addProduct`, `updateProduct`, `deleteProduct`, etc., all of which involves finding items in the `products` array and immutably updating it. This is boilerplate.

## `@ngrx/entity`: A Standardized Approach

`@ngrx/entity` provides a standard `EntityState` shape and an `EntityAdapter` to perform efficient CRUD operations on it.

The `EntityState` stores your collection in a normalized way:
-   `ids`: An array of all entity IDs, which maintains the sort order.
-   `entities`: A dictionary-like object (a map) that stores the actual entity data, keyed by the entity's ID.

This structure allows for very fast lookups (O(1) complexity) without having to iterate through an array.

- **Resource:** [Angular NgRx Entity - Complete Practical Guide](https://blog.angular-university.io/ngrx-entity/)
- **Resource:** [Official @ngrx/entity Guide](https://ngrx.io/guide/entity)

### 1. Setting up the Adapter

First, you define an `EntityState` and create an `EntityAdapter`.

**`products.reducer.ts`**
```typescript
import { createEntityAdapter, EntityAdapter, EntityState } from '@ngrx/entity';
import { Product } from './product.model';

// The EntityState interface extends our custom state with `ids` and `entities`.
export interface ProductsState extends EntityState<Product> {
  isLoading: boolean;
  error: any;
}

// Create the adapter.
// You can provide a `selectId` function if your ID property isn't `id`.
// You can provide a `sortComparer` to keep the `ids` array sorted.
export const productsAdapter: EntityAdapter<Product> = createEntityAdapter<Product>({
  sortComparer: (a, b) => a.name.localeCompare(b.name),
});

// Define the initial state using the adapter.
export const initialState: ProductsState = productsAdapter.getInitialState({
  isLoading: false,
  error: null,
});
```

### 2. Using the Adapter in the Reducer

The adapter provides a suite of methods for manipulating the state immutably. This dramatically simplifies your reducer.

**`products.reducer.ts` (continued)**
```typescript
import { createReducer, on } from '@ngrx/store';
import { ProductsApiActions } from './products.actions';

export const productsReducer = createReducer(
  initialState,
  on(ProductsApiActions.loadProductsSuccess, (state, { products }) => {
    // Replaces the entire collection.
    return productsAdapter.setAll(products, { ...state, isLoading: false });
  }),
  on(ProductsApiActions.addProductSuccess, (state, { product }) => {
    return productsAdapter.addOne(product, state);
  }),
  on(ProductsApiActions.updateProductSuccess, (state, { update }) => {
    // The update payload requires an `id` and a `changes` object.
    return productsAdapter.updateOne(update, state);
  }),
  on(ProductsApiActions.deleteProductSuccess, (state, { id }) => {
    return productsAdapter.removeOne(id, state);
  })
);
```
All the complexity of finding and updating items in the collection is handled by the adapter.

- **Resource:** [Entity Adapter API](https://ngrx.io/guide/entity/adapter)

## Performant Querying with Memoized Selectors

Now that we have our data in the store, we need an efficient way to query it. The `createSelector` function from `@ngrx/store` is the key.

**Selectors are memoized.** This means they keep a cache of the previous input arguments. If a selector is called again with the same arguments, it will return the cached result instead of re-running its calculation (the "projector function").

### How Memoization Works

1.  A selector is composed of input selectors and a projector function:
    `createSelector(inputSelector1, inputSelector2, (arg1, arg2) => { /* projector */ })`
2.  When the selector runs, it first executes the input selectors against the state.
3.  It compares the results of the input selectors to the results from the last run.
4.  **If the inputs are the same (by `===` reference check), it skips the projector and returns the cached output.**
5.  If any input has changed, it runs the projector function with the new inputs and caches the new result.

This is incredibly efficient, especially for selectors that perform expensive computations like filtering or mapping over large arrays.

- **Resource:** [Here's how NgRx selectors actually work internally](https://dev.to/davidshortman/heres-how-ngrx-selectors-actually-work-internally-15ml)

### Using Entity Adapter Selectors

The `@ngrx/entity` adapter also provides a set of pre-built, memoized selectors to get data from the entity state.

**`products.selectors.ts`**
```typescript
import { createFeatureSelector, createSelector } from '@ngrx/store';
import { ProductsState, productsAdapter } from './products.reducer';

// Get the selectors provided by the adapter
const {
  selectIds,
  selectEntities,
  selectAll,
  selectTotal,
} = productsAdapter.getSelectors();

// Select the top-level 'products' feature state
export const selectProductsState = createFeatureSelector<ProductsState>('products');

// Create memoized selectors by composing the feature selector
// with the adapter's selectors.
export const selectAllProducts = createSelector(selectProductsState, selectAll);
export const selectProductEntities = createSelector(selectProductsState, selectEntities);
export const selectProductCount = createSelector(selectProductsState, selectTotal);

// Example of a composed selector: get a single product by ID from the route
export const selectProductById = (id: string) => createSelector(
  selectProductEntities,
  (entities) => entities[id]
);
```
Now, in your components, you can use `store.select(selectAllProducts)` to get a sorted array of all products. This selector will only re-create the array if the underlying `ids` or `entities` in the state have actually changed, preventing unnecessary re-renders of your components.

By combining `@ngrx/entity` for state manipulation and memoized selectors for state querying, you can build a highly performant and maintainable system for managing collections of data in your global store.