# Lesson 2: SPA Project Scaffold

This lesson walks you through creating a modern Angular Single-Page Application (SPA) with a robust, production-ready toolchain. We will set up a new project with strict TypeScript, ESLint for linting, Prettier for formatting, Jest for unit testing, Angular Testing Library for component testing, Storybook for UI development, and Playwright for end-to-end testing.

## 1. Create a New Angular Project

The Angular CLI is the fastest way to get started. By default, it enables strict mode, which is a great starting point for a high-quality application.

- **Action:** Create a new Angular project. The CLI will prompt you for routing and a stylesheet format (we'll use SCSS).
  ```bash
  ng new my-awesome-app --style=scss --routing
  cd my-awesome-app
  ```
- **Resource:** [Angular CLI `ng new` documentation](https://angular.io/cli/new)

## 2. Add ESLint and Prettier

A consistent and clean codebase is crucial for maintainability. ESLint helps enforce code quality rules, while Prettier ensures uniform formatting.

- **Action:** Add `angular-eslint` to your project. This schematic will handle the necessary configuration.
  ```bash
  ng add @angular-eslint/schematics
  ```
- **Action:** Install Prettier and its ESLint integration packages.
  ```bash
  npm install --save-dev prettier eslint-config-prettier eslint-plugin-prettier
  ```
- **Action:** Create a `.prettierrc.json` file in your project root:
  ```json
  {
    "singleQuote": true,
    "arrowParens": "avoid",
    "trailingComma": "all"
  }
  ```
- **Action:** Create a `.prettierignore` file to prevent Prettier from formatting generated files and bundles:
  ```
  # Ignore paths for prettier
  /dist
  /coverage
  ```
- **Resource:** [Best Practices for Prettier & ESLint in Angular](https://www.angulararchitects.io/blog/best-practices-prettier-eslint/)

## 3. Replace Karma/Jasmine with Jest

Jest is a popular, fast, and feature-rich testing framework. We'll replace Angular's default Karma and Jasmine setup with Jest.

- **Action:** Remove Karma and Jasmine packages.
  ```bash
  npm uninstall karma karma-chrome-launcher karma-coverage karma-jasmine karma-jasmine-html-reporter jasmine-core jasmine-spec-reporter @types/jasmine
  ```
- **Action:** Install Jest and its Angular preset.
  ```bash
  npm install --save-dev jest @types/jest jest-preset-angular
  ```
- **Action:** Create a `jest.config.js` file in the root of your project:
  ```javascript
  module.exports = {
    preset: 'jest-preset-angular',
    setupFilesAfterEnv: ['<rootDir>/setup-jest.ts'],
  };
  ```
- **Action:** Create a `setup-jest.ts` file in the root of your project:
  ```typescript
  import 'jest-preset-angular/setup-jest';
  ```
- **Action:** Update `tsconfig.spec.json` to use Jest types:
  ```json
  {
    "extends": "./tsconfig.json",
    "compilerOptions": {
      "outDir": "./out-tsc/spec",
      "types": ["jest"]
    },
    "files": ["src/setup-jest.ts"],
    "include": ["src/**/*.spec.ts", "src/**/*.d.ts"]
  }
  ```
- **Resource:** [Setting Up Jest in Your Angular Project](https://medium.com/@philip.mutua/setting-up-jest-in-your-angular-16-project-3638ef65f3a3)
- **Action:** Verify the setup by running `npm test`. The default `app.component.spec.ts` should execute and pass with Jest.

## 4. Add Angular Testing Library

Angular Testing Library (ATL) provides light-weight utility functions to test components in a way that resembles how users interact with them.

- **Action:** Add Angular Testing Library to your project using `ng add`.
  ```bash
  ng add @testing-library/angular
  ```
- **Resource:** [Official Angular Testing Library Documentation](https://testing-library.com/docs/angular-testing-library/intro/)
- **Action:** Create a simple "hello world" test using ATL to verify the setup. Create a new file `src/app/app.component.atl.spec.ts`:
  ```typescript
  import { render, screen } from '@testing-library/angular';
  import { AppComponent } from './app.component';

  it('should render the title using ATL', async () => {
    await render(AppComponent);
    expect(screen.getByText('my-awesome-app is running!')).toBeInTheDocument();
  });
  ```
- Run `npm test` again to ensure both the original spec and the new ATL spec pass.

## 5. Add Storybook

Storybook allows you to develop and test UI components in isolation, which is a powerful way to build a robust component library.

- **Action:** Initialize Storybook in your Angular project.
  ```bash
  npx storybook init
  ```
  This command will detect that you are using Angular, install dependencies, and set up the necessary scripts and configuration. It will also create example stories.
- **Resource:** [Storybook for Angular Documentation](https://storybook.js.org/docs/angular/get-started/install)
- **Action:** Verify the setup by running `npm run storybook`. This should start the Storybook development server and open it in your browser, where you can see the example stories.

## 6. Add Playwright

Playwright is a modern end-to-end testing framework from Microsoft that allows you to test your application in Chromium, Firefox, and WebKit.

- **Action:** Add Playwright to your project using its `init` command.
  ```bash
  npm init playwright@latest
  ```
  Follow the prompts to configure Playwright. It's recommended to create a separate `e2e` directory for these tests. This will generate a default `example.spec.ts`.
- **Resource:** [Playwright Installation Guide](https://playwright.dev/docs/intro)
- **Action:** Verify the setup by running `npx playwright test`. This will execute the example test, which navigates to a few websites and takes screenshots, confirming the runner is working.

---

## ✅ Verifiable Outcome

After completing this lesson, you should have a new Angular project with the following commands working correctly:
1. **`npm run lint`**: Runs ESLint and Prettier to check code quality and formatting. It should pass without errors on the initial project structure.
2. **`npm test`**: Runs the Jest unit test runner. It should execute the default `app.component.spec.ts` and show all tests passing.
3. **`npm run storybook`**: Starts the Storybook development server, allowing you to view the default stories for the `Button` and `Header` components.
4. **`npx playwright test`**: Runs the Playwright E2E test runner. It should execute the default example tests successfully.