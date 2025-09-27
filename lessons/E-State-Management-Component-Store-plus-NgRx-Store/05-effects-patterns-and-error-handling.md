# Lesson 5: Effects Patterns and Error Handling

NgRx Effects are the primary place to orchestrate side effects in response to dispatched actions. This includes making HTTP requests, interacting with browser storage, or using WebSockets. Writing robust, predictable, and resilient effects is crucial for a stable application.

This lesson covers two key aspects of building high-quality effects: choosing the correct concurrency operator and implementing proper error handling.

## 1. Concurrency and Cancellation in Effects

The logic from the "Concurrency Semantics" lesson applies directly to NgRx Effects. The `createEffect` function takes an observable stream, and you will almost always use a flattening operator (`switchMap`, `concatMap`, `mergeMap`, `exhaustMap`) to manage the side effect.

Choosing the right operator is critical to prevent race conditions and ensure the desired user experience.

-   **`switchMap` for fetching data:** When an action is dispatched to fetch data (e.g., based on a route parameter), `switchMap` is usually the right choice. If a new fetch action comes in before the first one is complete, the old request is canceled.

    ```typescript
    loadProduct$ = createEffect(() => this.actions$.pipe(
      ofType(ProductsPageActions.loadProduct),
      switchMap(({ id }) =>
        this.productService.getProductById(id).pipe(
          map(product => ProductsApiActions.loadProductSuccess({ product })),
          catchError(error => of(ProductsApiActions.loadProductFailure({ error })))
        )
      )
    ));
    ```

-   **`concatMap` or `exhaustMap` for writes/updates:** When performing a write operation (create, update, delete), you almost never want to cancel it.
    -   `concatMap` will queue incoming requests, ensuring they happen one at a time.
    -   `exhaustMap` will ignore new requests while one is in flight, which is perfect for preventing double-submits.

    ```typescript
    updateProduct$ = createEffect(() => this.actions$.pipe(
      ofType(ProductsPageActions.updateProduct),
      exhaustMap(({ product }) =>
        this.productService.updateProduct(product).pipe(
          map(updatedProduct => ProductsApiActions.updateProductSuccess({ update: { id: updatedProduct.id, changes: updatedProduct } })),
          catchError(error => of(ProductsApiActions.updateProductFailure({ error })))
        )
      )
    ));
    ```

- **Resource:** [Your NGRX Effects are Probably Wrong](https://medium.com/@amcdnl/your-ngrx-effects-are-probably-wrong-574460868005) - An excellent article on choosing the right operator.

## 2. The Golden Rule of Error Handling in Effects

This is the most important pattern to understand when writing effects. If an error from your side effect (e.g., an `HttpErrorResponse`) reaches the main effect stream, **it will kill the effect**. The stream will complete, and the effect will stop listening for any new actions for the entire lifetime of the application.

**The Golden Rule:** The `catchError` operator must **always** be placed on the *inner* observable, not the outer one.

**WRONG - This effect will die on the first error:**
```typescript
// DO NOT DO THIS!
// The catchError is on the outer stream.
loadProductsWrong$ = createEffect(() => this.actions$.pipe(
  ofType(ProductsPageActions.loadProducts),
  mergeMap(() => this.productService.getAll()), // Inner observable
  map(products => ProductsApiActions.loadProductsSuccess({ products })),
  catchError(error => of(ProductsApiActions.loadProductsFailure({ error }))) // KILLS THE EFFECT!
));
```

**CORRECT - This effect will continue running after an error:**
```typescript
// DO THIS!
// The catchError is inside the inner stream.
loadProductsCorrect$ = createEffect(() => this.actions$.pipe(
  ofType(ProductsPageActions.loadProducts),
  mergeMap(() =>
    this.productService.getAll().pipe( // Inner observable
      map(products => ProductsApiActions.loadProductsSuccess({ products })),
      // By catching the error here, we prevent it from reaching the
      // main `actions$` stream. We return a new action instead.
      catchError(error => of(ProductsApiActions.loadProductsFailure({ error })))
    )
  )
));
```

By placing `catchError` on the inner stream, you handle the error gracefully (by dispatching a `Failure` action) and allow the main effect stream to continue listening for new actions.

- **Resource:** [Error Handling in NgRx Effects](https://medium.com/@saranipeiris17/error-handling-in-ngrx-effects-0d93bf9e92c8)
- **Resource:** [Stack Overflow: ngrx effects error handling](https://stackoverflow.com/questions/41685519/ngrx-effects-error-handling)

## 3. Using the `tapResponse` Operator

The `@ngrx/effects` package provides a useful utility operator called `tapResponse` that simplifies the common `map`/`catchError` pattern. It takes two arguments: a success callback and an error callback.

```typescript
import { tapResponse } from '@ngrx/operators';

loadProductsWithTapResponse$ = createEffect(() => this.actions$.pipe(
  ofType(ProductsPageActions.loadProducts),
  mergeMap(() =>
    this.productService.getAll().pipe(
      tapResponse(
        (products) => ProductsApiActions.loadProductsSuccess({ products }),
        (error) => ProductsApiActions.loadProductsFailure({ error })
      )
    )
  )
));
```

This operator is purely for convenience and does the exact same thing as the manual `map`/`catchError` pattern, but it can make your effects cleaner and more readable.

---

## ✅ Verifiable Outcome

You can verify the error handling pattern by creating a test that simulates an API failure.

1.  **Implement the "Wrong" Effect:**
    -   Create the `loadProductsWrong$` effect as described in the lesson, where `catchError` is placed on the outer stream.
    -   Use `HttpTestingController` in your test to mock the `productService.getAll()` call and make it return an error.
        ```typescript
        const req = httpTestingController.expectOne('/api/products');
        req.flush('Server error', { status: 500, statusText: 'Server Error' });
        ```
    -   In your test, dispatch the `loadProducts` action **twice**.

2.  **Observe the "Dead" Effect:**
    -   **Expected Result:** The test will show that the `loadProductsFailure` action was dispatched after the first attempt. However, the effect is now "dead." When the second `loadProducts` action is dispatched, the effect will not trigger, and no further HTTP requests will be made.

3.  **Implement the "Correct" Effect:**
    -   Refactor the effect to use the correct pattern, with `catchError` placed on the inner observable.
    -   Run the same test again, dispatching the `loadProducts` action twice and flushing the first request with an error.
    -   **Expected Result:** The `loadProductsFailure` action is dispatched after the first attempt. When the second `loadProducts` action is dispatched, the effect should trigger again, and you should see a **second** HTTP request being made in your test via `httpTestingController.expectOne()`. This proves the effect remained alive and continued listening for actions after the first error was handled.