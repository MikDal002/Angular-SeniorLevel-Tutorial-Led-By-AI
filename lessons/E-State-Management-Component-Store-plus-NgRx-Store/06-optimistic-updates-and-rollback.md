# Lesson 6: Optimistic Updates and Rollback

In a traditional ("pessimistic") update, the UI waits for confirmation from the server before showing that a change has been made. This is safe, but it can feel slow to the user.

**Optimistic updates** are a powerful pattern for creating a snappy, responsive user experience. The core idea is to update the UI *immediately*, assuming the server request will succeed. In the rare case that it fails, we then "roll back" the change in the UI.

This lesson covers how to implement this pattern in NgRx.

## The Optimistic Update Flow

Implementing an optimistic update requires a carefully orchestrated sequence of actions and effects:

1.  **Component Dispatches Action:** The user performs an action (e.g., clicks "update"). The component dispatches a single action with the intended changes (e.g., `[Products Page] Update Product`).
2.  **Optimistic Reducer Update:** The reducer immediately updates the entity in the store with the new values. The UI, which is subscribed to selectors, updates instantly.
3.  **Effect Triggers API Call:** An effect listens for the `Update Product` action. It needs the *original* state of the entity before the update, so it uses `withLatestFrom` to get the current state from the store *before* making the API call.
4.  **Handling Success:** If the API call succeeds, the effect dispatches a `Success` action. Often, this action doesn't need to do anything in the reducer, as the state is already correct. It's useful for signaling the end of the process (e.g., to hide a loading spinner).
5.  **Handling Failure (The Rollback):** If the API call fails, the effect dispatches a `Failure` action. Crucially, this action's payload includes the *original* entity data that was saved in the effect. The reducer then uses this data to revert the state back to how it was before the optimistic update.

## Example: Optimistically Updating a Product

Let's walk through the code for this pattern.

### 1. The Actions

We need three actions: the trigger, the success, and the failure (which includes the rollback data).

**`products.actions.ts`**
```typescript
import { createActionGroup, props } from '@ngrx/store';
import { Product } from './product.model';
import { Update } from '@ngrx/entity';

export const ProductsPageActions = createActionGroup({
  source: 'Products Page',
  events: {
    // The initial action dispatched by the component
    'Update Product': props<{ update: Update<Product> }>(),
  }
});

export const ProductsApiActions = createActionGroup({
  source: 'Products API',
  events: {
    // Dispatched by the effect on success
    'Update Product Success': props<{ product: Product }>(),
    // Dispatched by the effect on failure, with the original product for rollback
    'Update Product Failure': props<{ originalProduct: Product }>(),
  }
});
```

### 2. The Reducer with Rollback Logic

The reducer handles both the initial optimistic update and the potential rollback.

**`products.reducer.ts`**
```typescript
import { createReducer, on } from '@ngrx/store';
import { productsAdapter, ProductsState } from './products.adapter';
import { ProductsPageActions, ProductsApiActions } from './products.actions';

export const productsReducer = createReducer(
  // ... initial state
  on(ProductsPageActions.updateProduct, (state, { update }) => {
    // 1. Optimistically update the state immediately.
    return productsAdapter.updateOne(update, state);
  }),

  on(ProductsApiActions.updateProductFailure, (state, { originalProduct }) => {
    // 5. On failure, roll back the change using the original data.
    const update: Update<Product> = {
      id: originalProduct.id,
      changes: originalProduct
    };
    return productsAdapter.updateOne(update, state);
  })
  // Note: updateProductSuccess often doesn't need a reducer case if the
  // optimistic state is already correct.
);
```

### 3. The Effect

The effect is the orchestrator. It holds onto the original state before making the API call.

**`products.effects.ts`**
```typescript
import { Injectable } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { Store } from '@ngrx/store';
import { of } from 'rxjs';
import { map, catchError, concatMap, withLatestFrom } from 'rxjs/operators';
import { ProductsPageActions, ProductsApiActions } from './products.actions';
import { ProductService } from './product.service';
import { selectProductEntities } from './products.selectors';

@Injectable()
export class ProductsEffects {
  constructor(
    private actions$: Actions,
    private productService: ProductService,
    private store: Store
  ) {}

  updateProduct$ = createEffect(() => this.actions$.pipe(
    ofType(ProductsPageActions.updateProduct),
    concatMap(action =>
      // 3. Get the original state of the entity *before* the update.
      of(action).pipe(
        withLatestFrom(this.store.select(selectProductEntities))
      )
    ),
    concatMap(([action, entities]) => {
      const originalProduct = entities[action.update.id];
      if (!originalProduct) {
        return of(ProductsApiActions.updateProductFailure({ originalProduct: {} as Product }));
      }

      return this.productService.updateProduct(action.update.changes).pipe(
        // 4. On success, dispatch the success action.
        map(product => ProductsApiActions.updateProductSuccess({ product })),
        // 5. On failure, dispatch the failure action with the rollback data.
        catchError(() => of(ProductsApiActions.updateProductFailure({ originalProduct })))
      );
    })
  ));
}
```
*Note: We use `concatMap` here to ensure that update requests are processed sequentially, preventing race conditions.*

### Downsides and Considerations

-   **Complexity:** This pattern is more complex than a simple pessimistic update.
-   **Error UX:** You need a clear way to inform the user that the action they thought was successful has failed and been rolled back (e.g., with a toast notification).
-   **Not for Every Action:** Optimistic updates are best for operations that have a very high chance of success and where perceived performance is critical. For sensitive or complex operations (like financial transactions), a pessimistic approach is often safer.

---

## ✅ Verifiable Outcome

You can verify this pattern by creating a component and a test that simulates an API failure.

1.  **Implement the Full Flow:**
    -   Create the actions, reducer, and effect as described in the lesson.
    -   Create a component that displays a product's name from the store.
    -   Add a button that dispatches the `ProductsPageActions.updateProduct` action with a new name for the product (e.g., "Updated Name").

2.  **Test the Optimistic UI Update:**
    -   Run the application. The component should display the original product name.
    -   In your browser's DevTools, go to the "Network" tab and enable "Offline" mode to simulate a network failure.
    -   Click the "Update" button.
    -   **Expected Result:** The product's name in the UI should **immediately** change to "Updated Name", even though the network request will fail. This demonstrates the optimistic update.

3.  **Test the Rollback:**
    -   Keep the application running. The `updateProduct` effect will eventually fail because the network is offline.
    -   **Expected Result:** After the API call times out or fails, the product's name in the UI should **revert back** to its original value. In the Redux DevTools, you will see the `[Products Page] Update Product` action followed by the `[Products API] Update Product Failure` action. Inspecting the state after the failure action will show the original product data has been restored. This confirms the rollback logic is working correctly.