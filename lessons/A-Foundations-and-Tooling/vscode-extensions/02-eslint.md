# VS Code Extension: ESLint

ESLint is the industry-standard static analysis tool for JavaScript and TypeScript. It analyzes your code to find potential bugs, enforce coding standards, and maintain a consistent style. The ESLint extension for VS Code integrates this powerful tool directly into your editor.

- **Marketplace Link:** [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)

## Why It's Useful

-   **Real-time Feedback:** It highlights errors and warnings directly in your code as you type, providing immediate feedback without needing to run a separate command.
-   **Enforces Best Practices:** It helps you and your team adhere to a shared set of coding standards, improving code quality and consistency.
-   **Catches Bugs Early:** It can identify common programming errors, such as unused variables, unreachable code, or incorrect async/await usage.
-   **Automatic Fixes:** Many ESLint rules are "fixable," meaning you can run a command to automatically correct the violations, saving significant time.

## Mini-Tutorial

To see this extension in action, you first need to have ESLint set up in your Angular project (as covered in Lesson 2 of this module).

1.  **Install the extension** from the VS Code Marketplace.
2.  **Open a TypeScript file** in your project.
3.  **Introduce a linting error:**
    ```typescript
    // app.component.ts
    export class AppComponent {
      // ESLint will flag this variable because it is declared but never used.
      const title = 'my-awesome-app';
    }
    ```
4.  **Observe the Error:**
    -   **Expected Result:** The variable `title` will be underlined with a green or yellow squiggle. Hovering over it will show the ESLint error message, such as `"'title' is assigned a value but never used. (@typescript-eslint/no-unused-vars)"`.

5.  **Test Auto-Fix:**
    -   Open the command palette (`Ctrl+Shift+P`).
    -   Type "ESLint: Fix all auto-fixable problems" and run the command.
    -   **Expected Result:** The extension will automatically remove the unused `title` variable, resolving the linting error. This demonstrates the power of automated code cleanup.