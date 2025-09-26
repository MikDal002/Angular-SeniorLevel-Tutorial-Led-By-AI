# Lesson 7: Testing Reducers, Selectors, and Effects

A major advantage of using NgRx is that it makes your state management logic highly testable. Because reducers and selectors are pure functions, and effects are isolated streams, we can write focused, reliable unit tests for each piece of the puzzle.

## 1. Testing Reducers

A reducer is a pure function. Its only job is to take the previous state and an action, and return a new state. This makes testing them the most straightforward part of NgRx.

**The Strategy:**
1.  Define an initial state.
2.  Create an action.
3.  Call the reducer function with the initial state and the action.
4.  Assert that the returned state is what you expect.

**Example:**
```typescript
// products.reducer.spec.ts
import { productsReducer, initialState } from './products.reducer';
import { ProductsApiActions } from './products.actions';
import { Product } from './product.model';

describe('Products Reducer', () => {
  it('should return the initial state on an unknown action', () => {
    const action = {} as any;
    const state = productsReducer(initialState, action);
    expect(state).toBe(initialState);
  });

  it('should add a product on addProductSuccess', () => {
    const newProduct: Product = { id: '1', name: 'New Product' };
    const action = ProductsApiActions.addProductSuccess({ product: newProduct });
    const state = productsReducer(initialState, action);

    expect(state.entities['1']).toEqual(newProduct);
    expect(state.ids).toContain('1');
  });

  it('should update a product on updateProductSuccess', () => {
    const originalState = {
      ...initialState,
      ids: ['1'],
      entities: { '1': { id: '1', name: 'Original' } }
    };
    const update = { id: '1', changes: { name: 'Updated' } };
    const action = ProductsApiActions.updateProductSuccess({ update });
    const state = productsReducer(originalState, action);

    expect(state.entities['1']?.name).toEqual('Updated');
  });
});
```
- **Resource:** [Testing Reducers in NGRX Store](https://ultimatecourses.com/blog/ngrx-store-testing-reducers)

## 2. Testing Selectors

Selectors are also pure functions that take state as input and return a slice of that state. Memoized selectors created with `createSelector` have a handy `.projector()` method that allows you to test the selector's transformation logic in isolation, without needing to mock the entire state tree.

**The Strategy:**
1.  Create a mock state object that contains the data your selector needs.
2.  For simple selectors, call the selector function directly with the mock state.
3.  For composed selectors, call the `.projector()` method with the expected inputs.
4.  Assert that the result is what you expect.

**Example:**
```typescript
// products.selectors.spec.ts
import * as fromProducts from './products.reducer';
import { selectAllProducts, selectProductCount } from './products.selectors';

describe('Products Selectors', () => {
  const initialState: fromProducts.ProductsState = fromProducts.productsAdapter.getInitialState({
    isLoading: false,
    error: null,
    ids: ['1', '2'],
    entities: {
      '1': { id: '1', name: 'Product A' },
      '2': { id: '2', name: 'Product B' },
    }
  });

  it('should select all products', () => {
    const result = selectAllProducts.projector(initialState);
    expect(result.length).toBe(2);
    expect(result[0].name).toBe('Product A');
  });

  it('should select the total product count', () => {
    const result = selectProductCount.projector(initialState);
    expect(result).toBe(2);
  });
});
```
- **Resource:** [How I test my NgRx selectors](https://timdeschryver.dev/blog/how-i-test-my-ngrx-selectors)

## 3. Testing Effects

Testing effects is more involved because they deal with asynchronous operations and dependencies. The key is to mock the dependencies (like services) and provide a mock stream of actions.

**The Strategy:**
1.  Use `TestBed` to provide your effect class, `provideMockActions`, and a mock for any services the effect uses.
2.  Create a source observable for the actions stream (`actions$`). This is what you will use to "dispatch" a test action.
3.  Subscribe to your effect and assert that it dispatches the expected success or failure action in response to the source action.

**Example:**
```typescript
// products.effects.spec.ts
import { TestBed } from '@angular/core/testing';
import { provideMockActions } from '@ngrx/effects/testing';
import { Observable, of, throwError } from 'rxjs';
import { ProductsEffects } from './products.effects';
import { ProductService } from './product.service';
import { ProductsPageActions, ProductsApiActions } from './products.actions';

describe('ProductsEffects', () => {
  let actions$: Observable<any>;
  let effects: ProductsEffects;
  let productService: jasmine.SpyObj<ProductService>;

  beforeEach(() => {
    const productServiceSpy = jasmine.createSpyObj('ProductService', ['getAll']);

    TestBed.configureTestingModule({
      providers: [
        ProductsEffects,
        provideMockActions(() => actions$),
        { provide: ProductService, useValue: productServiceSpy },
      ],
    });

    effects = TestBed.inject(ProductsEffects);
    productService = TestBed.inject(ProductService) as jasmine.SpyObj<ProductService>;
  });

  it('should dispatch loadProductsSuccess on successful load', (done) => {
    const products = [{ id: '1', name: 'Test Product' }];
    const action = ProductsPageActions.loadProducts();
    const outcome = ProductsApiActions.loadProductsSuccess({ products });

    actions$ = of(action); // "Dispatch" the trigger action
    productService.getAll.and.returnValue(of(products)); // Mock the service call

    effects.loadProducts$.subscribe(resultAction => {
      expect(resultAction).toEqual(outcome);
      done(); // Signal that the async test is complete
    });
  });

  it('should dispatch loadProductsFailure on failed load', (done) => {
    const error = { message: 'Error' };
    const action = ProductsPageActions.loadProducts();
    const outcome = ProductsApiActions.loadProductsFailure({ error });

    actions$ = of(action);
    productService.getAll.and.returnValue(throwError(() => error));

    effects.loadProducts$.subscribe(resultAction => {
      expect(resultAction).toEqual(outcome);
      done();
    });
  });
});
```
- **Resource:** [Testing NgRx Effects with Async/Await](https://www.herodevs.com/blog-posts/testing-ngrx-effects-with-async-await)

By thoroughly testing your reducers, selectors, and effects, you can build a robust and reliable state management layer, giving you confidence that your application behaves as expected.