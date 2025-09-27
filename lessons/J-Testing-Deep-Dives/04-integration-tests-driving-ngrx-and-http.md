# Lesson 4: Integration Tests Driving NgRx and HTTP

Unit tests are great for testing services, reducers, and effects in isolation. Component tests are great for testing a component's template and behavior. But to have full confidence in a feature, you need **integration tests** that verify how all these pieces work together.

An integration test for an NgRx feature typically involves:
-   Rendering a "smart" container component.
-   Simulating user interaction (e.g., clicking a "Load Data" button).
-   Mocking the `HttpClient` to control API responses.
-   Asserting that the correct actions are dispatched and that the component's view updates as expected.

This lesson shows how to use `@testing-library/angular`, `@ngrx/store/testing`, and `@angular/common/http/testing` to write a robust integration test for a feature flow.

## The Test Scenario

We have a simple feature that fetches a list of products.
1.  **Component:** A `ProductsContainerComponent` with a "Load Products" button. When clicked, it dispatches a `[Products Page] Load Products` action. It uses a selector to display the products from the store.
2.  **Effect:** A `ProductsEffects` listens for the `Load Products` action, calls a `ProductService` to fetch data, and dispatches a `[Products API] Load Products Success` or `Failure` action.
3.  **Reducer:** The `productsReducer` handles the `Success` action by adding the products to the state.

## The Integration Test

Our test will simulate this entire flow, from the button click to the final rendered output.

### 1. Setting up the Test

We need to provide our real components, effects, and reducers, but we'll use a `MockStore` to spy on actions and `HttpClientTestingModule` to mock the backend.

```typescript
// products.integration.spec.ts
import { render, screen, fireEvent } from '@testing-library/angular';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { provideMockStore, MockStore } from '@ngrx/store/testing';
import { provideMockActions } from '@ngrx/effects/testing';
import { ProductsContainerComponent } from './products-container.component';
import { ProductsEffects } from './state/products.effects';
import { productsReducer } from './state/products.reducer';
import { ProductService } from './product.service';
import { provideStore, Store } from '@ngrx/store';
import { provideEffects } from '@ngrx/effects';

describe('Products Feature Integration Test', () => {
  let httpTestingController: HttpTestingController;
  let store: Store;

  async function setup() {
    await render(ProductsContainerComponent, {
      imports: [HttpClientTestingModule], // Import the testing module
      providers: [
        // Provide the REAL store, effects, and reducers
        provideStore({ products: productsReducer }),
        provideEffects([ProductsEffects]),
        ProductService, // The real service that uses HttpClient
      ],
    });

    // Inject the tools we need to control the test
    httpTestingController = TestBed.inject(HttpTestingController);
    store = TestBed.inject(Store);
  }

  afterEach(() => {
    // Verify that no requests are outstanding after each test
    httpTestingController.verify();
  });

  // ... tests go here
});
```
*Note: For integration tests, we provide the real store and effects, not mocks, because we want to test their interaction.*

### 2. Writing the Test

The test will follow the user's journey.

```typescript
// ... inside the describe block

it('should load and display products when the load button is clicked', async () => {
  await setup();

  // 1. Initial state: No products should be visible.
  expect(screen.queryByRole('listitem')).not.toBeInTheDocument();

  // 2. ACT: Simulate the user clicking the "Load" button.
  const loadButton = screen.getByRole('button', { name: /load products/i });
  fireEvent.click(loadButton);

  // 3. HTTP Mocking: Expect that a request was made to the products API.
  const req = httpTestingController.expectOne('/api/products');
  expect(req.request.method).toEqual('GET');

  // 4. HTTP Mocking: Respond with mock data.
  const mockProducts = [{ id: '1', name: 'Test Product' }];
  req.flush(mockProducts);

  // 5. ASSERT: Check that the UI has updated correctly.
  // The component should have received the data from the store
  // and rendered it to the screen.
  const productItem = await screen.findByText(/test product/i);
  expect(productItem).toBeInTheDocument();
});

it('should display an error message if the API call fails', async () => {
  await setup();

  // 2. ACT: Click the button.
  const loadButton = screen.getByRole('button', { name: /load products/i });
  fireEvent.click(loadButton);

  // 3. HTTP Mocking: Expect the request.
  const req = httpTestingController.expectOne('/api/products');

  // 4. HTTP Mocking: Respond with an error.
  req.flush('Something went wrong', { status: 500, statusText: 'Server Error' });

  // 5. ASSERT: Check that an error message is now visible in the UI.
  const errorMessage = await screen.findByText(/could not load products/i);
  expect(errorMessage).toBeInTheDocument();
});
```

### Why This is an Integration Test

This test verifies that:
-   The button click in the component correctly dispatches the `Load Products` action.
-   The `ProductsEffects` is listening for that action.
-   The effect correctly calls the `ProductService`.
-   The `ProductService` correctly makes an HTTP request to the right URL.
-   When the HTTP request is flushed with a success response, the effect dispatches the `Success` action.
-   The `productsReducer` correctly processes the `Success` action and updates the state.
-   The component's selector correctly reads the new state and updates the view.

---

## ✅ Verifiable Outcome

You can verify your understanding of this testing pattern by implementing the integration test described in the lesson.

1.  **Build the Feature:**
    -   Create the `ProductsContainerComponent`, `ProductService`, and the NgRx files (`actions`, `reducer`, `effects`, `selectors`) for a "products" feature.

2.  **Write the Integration Test:**
    -   Create the `products.integration.spec.ts` file.
    -   Implement the `setup` function that uses `TestBed` to provide the real store, effects, and services, along with the `HttpClientTestingModule`.
    -   Write the two test cases: one for the success scenario and one for the failure scenario.

3.  **Run the Test:**
    -   Execute `ng test`.
    -   **Expected Result:** Both integration tests should pass.
        -   The success test will confirm that a user action can trigger a chain of events through the entire NgRx stack, resulting in a mocked HTTP call and a final UI update.
        -   The failure test will confirm that if the mocked HTTP call returns an error, the UI correctly displays the appropriate error state.
    -   This confirms your ability to write high-level tests that validate the complete functionality of a feature slice.