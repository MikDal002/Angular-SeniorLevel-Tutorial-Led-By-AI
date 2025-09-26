# Lesson 4: GitHub Actions CI Baseline

A Continuous Integration (CI) pipeline is essential for maintaining code quality and automating repetitive tasks. This lesson will guide you through setting up a baseline CI workflow for your Angular application using GitHub Actions. The workflow will run on every push and pull request, performing the following steps:

1.  **Install Dependencies:** Check out the code and install `npm` dependencies, using a cache to speed up the process.
2.  **Lint and Type-Check:** Run ESLint and the TypeScript compiler to catch static analysis errors.
3.  **Run Unit and Component Tests:** Execute the Jest test suite.
4.  **Run End-to-End (E2E) Tests:** Run the Playwright E2E test suite.
5.  **Upload Artifacts:** Store the test results as artifacts for later inspection.

## 1. Create the Workflow File

GitHub Actions are defined in YAML files located in the `.github/workflows` directory of your repository.

- **Action:** Create a new file named `ci.yml` in `.github/workflows/`.
  ```yaml
  name: Angular CI

  on:
    push:
      branches: [ main ]
    pull_request:
      branches: [ main ]

  jobs:
    build_and_test:
      runs-on: ubuntu-latest

      steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Cache node_modules
        id: cache-npm
        uses: actions/cache@v3
        with:
          path: node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      - name: Install Dependencies
        if: steps.cache-npm.outputs.cache-hit != 'true'
        run: npm install

      - name: Lint
        run: npm run lint

      - name: Type-Check
        run: npx tsc --noEmit

      - name: Run Unit Tests
        run: npm test -- --coverage

      - name: Upload Test Coverage
        uses: actions/upload-artifact@v3
        with:
          name: coverage
          path: coverage/

      - name: Install Playwright Browsers
        run: npx playwright install --with-deps

      - name: Run E2E Tests
        run: npx playwright test

      - name: Upload E2E Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/
  ```

## 2. Understanding the Workflow

Let's break down the key parts of this workflow file.

### `on`

This section defines the triggers for the workflow. In this case, it runs on every `push` to the `main` branch and on every `pull_request` that targets the `main` branch.

### `jobs`

A workflow is made up of one or more jobs. We have a single job named `build_and_test` that runs on an `ubuntu-latest` runner.

### `steps`

Each job has a sequence of steps.

- **`actions/checkout@v3`:** This action checks out your repository so the workflow can access it.
- **`actions/setup-node@v3`:** This action sets up a Node.js environment.
- **`actions/cache@v3`:** This is a crucial step for performance. It caches the `node_modules` directory based on a key generated from the `package-lock.json` file. On subsequent runs, if the lock file hasn't changed, the dependencies are restored from the cache, which is much faster than a full `npm install`.
  - **Resource:** [Caching dependencies to speed up workflows](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- **`npm install`:** This step only runs if the cache was not hit, meaning the dependencies were not restored from the cache.
- **`npm run lint` and `npx tsc --noEmit`:** These commands run the linter and the TypeScript compiler (without emitting JavaScript files) to perform static analysis on the code.
- **`npm test -- --coverage`:** This runs the Jest test suite and generates a coverage report.
- **`actions/upload-artifact@v3`:** This action is used twice. First, to upload the test coverage report, and second, to upload the Playwright test results. This allows you to download and inspect these files after the workflow has completed. The `if: always()` condition ensures that the E2E test results are uploaded even if the tests fail.
  - **Resource:** [Storing workflow data as artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- **`npx playwright install --with-deps` and `npx playwright test`:** These commands install the necessary browsers for Playwright and then run the E2E tests.
  - **Resource:** [Playwright on CI](https://playwright.dev/docs/ci-intro)

## 3. Add Scripts to `package.json`

Ensure your `package.json` has the necessary scripts for this workflow to run.

```json
"scripts": {
  "ng": "ng",
  "start": "ng serve",
  "build": "ng build",
  "watch": "ng build --watch --configuration development",
  "test": "jest",
  "lint": "ng lint",
  "e2e": "playwright test",
  "release": "semantic-release",
  "prepare": "husky install"
}
```

With this CI pipeline in place, you have a solid foundation for ensuring the quality and stability of your Angular application. You can now commit this file to your repository and see it in action on your next push or pull request.