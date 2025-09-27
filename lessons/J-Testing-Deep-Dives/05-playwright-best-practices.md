# Lesson 5: Playwright Best Practices (Network, Tracing, Retries)

Writing end-to-end (E2E) tests that are fast, reliable, and easy to debug is crucial for a healthy CI/CD pipeline. This lesson covers three advanced Playwright features that help you achieve this: network mocking, test retries, and the trace viewer.

## 1. Network Mocking

E2E tests that rely on a live backend can be slow and flaky. If the backend is down or has a bug, your frontend tests will fail, even if the UI code is correct. **Network mocking** solves this by allowing you to intercept network requests made by the application and provide a fake, or "mock," response directly in your test.

This makes your tests:
-   **Fast:** No real network latency.
-   **Reliable:** Not dependent on a live backend.
-   **Deterministic:** You can test specific edge cases by crafting mock error responses.

Playwright's `page.route()` method is used to intercept network requests.

- **Resource:** [Playwright Documentation: Mock APIs](https://playwright.dev/docs/mock)

### Example: Mocking a Product API

Let's test a component that fetches and displays a list of products.

```typescript
// products.spec.ts
import { test, expect } from '@playwright/test';

test('should display products fetched from the API', async ({ page }) => {
  // 1. Define the mock response data.
  const mockProducts = [
    { id: '1', name: 'Test Product A' },
    { id: '2', name: 'Test Product B' },
  ];

  // 2. Intercept requests to the products API endpoint.
  await page.route('**/api/products', async route => {
    // 3. Fulfill the request with a mock JSON response.
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(mockProducts),
    });
  });

  // 4. Navigate to the page. The component will now receive our mock data.
  await page.goto('/products');

  // 5. Assert that the mock data is rendered correctly.
  await expect(page.getByText('Test Product A')).toBeVisible();
  await expect(page.getByText('Test Product B')).toBeVisible();
});
```
You can also use `route.fulfill()` to simulate network errors (e.g., `status: 500`) to test your application's error handling logic.

## 2. Test Retries

E2E tests can sometimes be "flaky," failing intermittently due to minor timing issues, network blips, or slow-loading resources. Playwright helps combat this by automatically **retrying** failed tests.

This feature is configured in `playwright.config.ts`.

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // How many times to retry a failed test.
  // For CI, 2 is a common setting. For local development, 0 or 1 is typical.
  retries: process.env.CI ? 2 : 0,

  // ... other config
});
```
When a test fails, Playwright will discard the failed run and start over in a fresh worker process. This simple configuration can dramatically improve the stability of your test suite.

- **Resource:** [Playwright Documentation: Retries](https://playwright.dev/docs/test-retries)

## 3. The Trace Viewer: Your Time-Traveling Debugger

When a test fails in a CI environment, it can be very difficult to diagnose what went wrong. You don't have access to the browser's DevTools, and a simple screenshot often doesn't tell the whole story.

Playwright's **Trace Viewer** is the solution. It records a detailed trace of a test's execution, including:
-   A filmstrip of screenshots for every action.
-   A full DOM snapshot at each step.
-   Console logs.
-   Network requests and responses.
-   Source code for the test.

This entire trace is packaged into a single `.zip` file that you can download and open locally, giving you a full, time-traveling debugging experience for your failed CI tests.

### Configuring Tracing

The best practice is to only generate traces for tests that fail after being retried. This avoids cluttering your test artifacts with traces for successful runs or flaky tests that pass on a retry.

This is configured in `playwright.config.ts`:

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  use: {
    // ... other `use` options

    // 'on-first-retry': Record a trace only on the first retry of a failed test.
    // 'retain-on-failure': Records a trace for every test, but deletes it if the test passes. Good for local debugging.
    trace: 'on-first-retry',
  },
  // ...
});
```

When a test fails in CI, you can download the `trace.zip` file from your build artifacts. To view it, simply drag and drop the file into [Playwright's online trace viewer](https://trace.playwright.dev/) or run the following command in your terminal:

```bash
npx playwright show-trace path/to/your/trace.zip
```

The Trace Viewer is one of Playwright's most powerful features, turning what used to be a frustrating debugging process into a straightforward investigation.

- **Resource:** [Playwright Documentation: Trace Viewer](https://playwright.dev/docs/trace-viewer-intro)

---

## ✅ Verifiable Outcome

You can verify these best practices by implementing them in your Playwright test suite.

1.  **Test Network Mocking:**
    -   Write a test for a component that fetches data, similar to the "Mocking a Product API" example.
    -   Use `page.route()` to intercept the API call and provide a mock response.
    -   Run the test.
    -   **Expected Result:** The test should pass very quickly. In the test report or console output, you should see no actual network request being made to your backend API, proving that the request was successfully mocked.

2.  **Test Retries and Tracing:**
    -   Configure `retries: 1` and `trace: 'on-first-retry'` in your `playwright.config.ts`.
    -   Create a deliberately "flaky" test that is designed to fail the first time but pass the second time. A simple way to do this is with a global flag:
        ```typescript
        let firstRun = true;
        test('flaky test', async ({ page }) => {
          if (firstRun) {
            firstRun = false;
            await expect(page.locator('body')).toHaveText('Something that does not exist');
          }
          await expect(page.locator('body')).not.toHaveText('Something that does not exist');
        });
        ```
    -   Run `npx playwright test`.
    -   **Expected Result:** In your console, you will see that the test failed once and was immediately retried. The second run will pass, and the overall test suite will be marked as successful.
    -   Now, check your `playwright-report` folder. You will find a `trace.zip` file for the failed first attempt. Run `npx playwright show-trace path/to/your/trace.zip`. The Trace Viewer will open, allowing you to inspect the exact reason for the initial failure. This confirms both the retry and tracing mechanisms are working as configured.