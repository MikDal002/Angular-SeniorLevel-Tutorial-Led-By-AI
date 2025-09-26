# Lesson 7: E2E Auth Scenarios with Playwright

End-to-end (E2E) testing for authentication flows can be tricky. You want to verify that your application behaves correctly when a user is logged in or logged out, but you don't want your tests to depend on the UI of a third-party identity provider, which is slow, brittle, and outside of your control.

The solution is to **mock the authenticated state**. Instead of logging in through the UI, we will programmatically set the authentication tokens in the browser's storage *before* the test runs. This allows us to test our application's protected routes and features in isolation.

- **Resource:** [Playwright Documentation: Authentication](https://playwright.dev/docs/auth)

## The Strategy: Reusing Authentication State

Playwright has a built-in concept for this exact scenario. The strategy involves two parts:

1.  **A "Setup" Test:** A special, one-time test that performs the login action and saves the browser's state (including `localStorage`, `sessionStorage`, and cookies) to a file.
2.  **Real Tests:** The actual E2E tests, which load the saved authentication state before each run, effectively starting the test in an already-logged-in state.

### 1. Configure Playwright for an Auth Setup File

First, we need to tell Playwright about our setup file in `playwright.config.ts`.

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // ... other config
  projects: [
    // This project is only for authentication
    { name: 'setup', testMatch: /.*\.setup\.ts/ },

    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        // Use the saved authentication state.
        storageState: 'playwright/.auth/user.json',
      },
      // Depend on the 'setup' project to run first.
      dependencies: ['setup'],
    },
  ],
});
```

### 2. Create the Authentication Setup Test

This test will navigate to a blank page, inject our mock tokens into `localStorage`, and then save the state. We don't even need to visit our actual application here.

**Important:** For this to work, your `AuthService` must be written to check for tokens in `localStorage` on startup. While not the most secure option for production (in-memory is better), using `localStorage` is often a necessary and acceptable trade-off to enable stable E2E testing.

```typescript
// tests/auth.setup.ts
import { test as setup, expect } from '@playwright/test';

const authFile = 'playwright/.auth/user.json';

setup('authenticate', async ({ page }) => {
  // We don't need to visit the app, just a blank page to get a browser context.
  await page.goto('about:blank');

  // Create fake but valid-looking JWTs.
  // In a real project, you might have a helper to generate these.
  const fakeIdToken = '...'; // A base64-encoded JWT payload
  const fakeAccessToken = '...';

  // The key for localStorage should match what your app uses.
  const mockAuthState = {
    access_token: fakeAccessToken,
    id_token: fakeIdToken,
    // ... any other properties your app expects
  };

  // Set the mock authentication state in localStorage.
  await page.evaluate(state => {
    window.localStorage.setItem('my-app-auth', JSON.stringify(state));
  }, mockAuthState);

  // Save the storage state to the file path we configured.
  await page.context().storageState({ path: authFile });
});
```

### 3. Write Tests for Protected Routes

Now, your regular tests will automatically run in a logged-in state because of the `storageState` and `dependencies` configuration.

```typescript
// tests/admin-dashboard.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Admin Dashboard', () => {
  test('should allow a logged-in user to see the dashboard', async ({ page }) => {
    // The test starts already authenticated.
    // No need to go through the login flow.
    await page.goto('/admin/dashboard');

    // Verify that we can see content on the protected page.
    await expect(page.locator('h1')).toHaveText('Admin Dashboard');
  });

  test('should redirect an unauthenticated user to login', async ({ browser }) => {
    // For this test, we need a clean, unauthenticated context.
    const context = await browser.newContext({ storageState: undefined });
    const page = await context.newPage();

    await page.goto('/admin/dashboard');

    // Verify that the user was redirected to the login page.
    await expect(page).toHaveURL(/.*\/login/);
  });
});
```

### 4. Testing the Logout Flow

We can also test the logout flow by starting authenticated and then clicking the logout button.

```typescript
// tests/logout.spec.ts
import { test, expect } from '@playwright/test';

test('logout flow', async ({ page }) => {
  // Start logged in.
  await page.goto('/admin/dashboard');
  await expect(page.locator('h1')).toHaveText('Admin Dashboard');

  // Find and click the logout button.
  await page.getByRole('button', { name: 'Logout' }).click();

  // Assert that we have been redirected to the login page or a logged-out page.
  await expect(page).toHaveURL(/.*\/login/);

  // Assert that the localStorage has been cleared.
  const storedAuth = await page.evaluate(() =>
    window.localStorage.getItem('my-app-auth')
  );
  expect(storedAuth).toBeNull();
});
```

By mocking the authentication state, you can create fast, reliable, and focused E2E tests for your application's core features without the flakiness of interacting with a third-party UI.