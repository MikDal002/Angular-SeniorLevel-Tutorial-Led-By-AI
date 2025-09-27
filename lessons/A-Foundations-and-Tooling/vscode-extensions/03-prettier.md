# VS Code Extension: Prettier - Code formatter

Prettier is an opinionated code formatter that enforces a consistent style across your entire codebase. It takes your code and reprints it from scratch, following a set of clear and consistent rules. The VS Code extension makes this process seamless.

- **Marketplace Link:** [Prettier - Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)

## Why It's Useful

-   **Ends All Style Debates:** Single quotes or double quotes? 2 spaces or 4? Prettier makes the decision for you, ending pointless arguments and allowing your team to focus on what matters.
-   **Consistent Code:** It ensures that every file in your project has the exact same formatting, making the code easier to read and understand, no matter who wrote it.
-   **Automated Formatting:** You can configure the extension to format your code automatically every time you save a file, requiring zero manual effort to keep your code clean.

## Mini-Tutorial

To see this extension in action, you first need to have Prettier set up in your Angular project (as covered in Lesson 2 of this module).

1.  **Install the extension** from the VS Code Marketplace.
2.  **Configure "Format On Save":**
    -   Open your VS Code settings (`Ctrl+,` or `Cmd+,`).
    -   Search for "Format On Save".
    -   Ensure the checkbox is ticked.
    -   It's also recommended to set Prettier as the default formatter for your TypeScript and HTML files.
3.  **Open a TypeScript file** and intentionally mess up the formatting.
    ```typescript
    // app.component.ts
    export class AppComponent {
    title = 'my-app';
      constructor() {
    console.log('hello');
      }
    }
    ```
4.  **Save the File:**
    -   Press `Ctrl+S` or `Cmd+S`.
    -   **Expected Result:** The moment you save, the code should instantly be reformatted to be clean and consistent:
        ```typescript
        export class AppComponent {
          title = 'my-app';
          constructor() {
            console.log('hello');
          }
        }
        ```
This automatic, on-save formatting is a huge productivity boost and a cornerstone of maintaining a clean, professional codebase.