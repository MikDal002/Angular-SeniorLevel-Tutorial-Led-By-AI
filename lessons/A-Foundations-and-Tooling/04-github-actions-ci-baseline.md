# Lesson 4: GitHub Actions CI & Release Baseline

A Continuous Integration (CI) pipeline is essential for maintaining code quality. A Continuous Deployment (CD) pipeline automates the release process. This lesson will guide you through setting up a baseline CI/CD workflow for your Angular application using GitHub Actions.

The workflow will:
1.  **On every push/PR to `main`:** Run all quality checks (lint, test, coverage, etc.).
2.  **On every push of a version tag (e.g., `v1.0.0`):** Run all quality checks AND create a new GitHub Release with the built application attached as an asset.

## 1. Create the Workflow File

- **Action:** Create a new file named `ci.yml` in `.github/workflows/`.

  ```yaml
  name: Angular CI & Release

  on:
    push:
      branches: [ main ]
      tags:
        - 'v*.*.*' # Run on version tags like v1.0.0
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
          run: npm ci
        - name: Lint
          run: npm run lint
        - name: Type-Check
          run: npx tsc --noEmit
        - name: Run Unit Tests with Coverage
          run: npm test -- --coverage
        - name: Enforce Coverage Threshold
          run: npx jest --coverage --coverageReporters="json-summary" | npx istanbul-threshold --coverage "./coverage/coverage-summary.json" --thresholds.global.lines=20
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

    release:
      if: startsWith(github.ref, 'refs/tags/')
      needs: build_and_test
      runs-on: ubuntu-latest
      steps:
        - name: Checkout
          uses: actions/checkout@v3
        - name: Setup Node.js
          uses: actions/setup-node@v3
          with:
            node-version: '18'
        - name: Install Dependencies
          run: npm ci
        - name: Build Application
          run: npm run build -- --configuration production
        - name: Create Release Archive
          run: tar -czf release.tgz -C dist/my-awesome-app . # Ensure 'my-awesome-app' matches your project name in angular.json
        - name: Create GitHub Release
          uses: softprops/action-gh-release@v1
          with:
            files: release.tgz
  ```

## 2. Understanding the Workflow

### `on`
-   `pull_request` and `push` to `main`: These triggers run the `build_and_test` job to ensure code quality.
-   `push` to `tags` matching `v*.*.*`: This trigger runs both the `build_and_test` job and the new `release` job.

### `jobs`
-   **`build_and_test`**: This job runs all our quality checks. The `Enforce Coverage Threshold` step will fail the build if test coverage for lines drops below 20%.
-   **`release`**: This new job is for publishing.
    -   `if: startsWith(github.ref, 'refs/tags/')`: This condition ensures the job *only* runs when the push event is for a tag.
    -   `needs: build_and_test`: This ensures we only create a release if all tests and quality gates have passed.
    -   **`Create GitHub Release`**: Uses the popular `softprops/action-gh-release` community action to create a new release on GitHub. It automatically uses the tag name (e.g., v1.0.0) for the release and attaches the `release.tgz` file as an asset.

## 3. Add Scripts and Dependencies

- **Action:** Ensure your `package.json` has the necessary scripts.
  ```json
  "scripts": {
    "build": "ng build",
    "test": "jest",
    "lint": "ng lint"
  }
  ```
- **Action:** Add the `istanbul-threshold` package for the coverage check.
  ```bash
  npm install --save-dev istanbul-threshold
  ```

---

## ✅ Verifiable Outcome

After committing the `.github/workflows/ci.yml` file, you can verify the outcome.

1.  **Check a PR/Push Run:**
    -   Push a commit to `main` or open a Pull Request.
    -   **Expected Result:** The `build_and_test` job should run and pass. The `release` job should be skipped.

2.  **Test the Release Job:**
    -   Ensure your `main` branch is up to date and all tests are passing.
    -   Create and push a new git tag:
        ```bash
        git tag v1.0.0
        git push origin v1.0.0
        ```
    -   Go to the "Actions" tab in your GitHub repository.
    -   **Expected Result:** A new workflow run will be triggered by the tag push. Both the `build_and_test` job and the `release` job will execute. Once complete, go to the "Releases" section of your repository. You should see a new release named "v1.0.0" with a `release.tgz` file attached as a downloadable asset.