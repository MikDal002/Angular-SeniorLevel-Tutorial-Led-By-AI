# VS Code Extension: Angular Language Service

This is the official Angular extension from the Angular team and is considered **essential** for any Angular developer using VS Code.

- **Marketplace Link:** [Angular Language Service](https://marketplace.visualstudio.com/items?itemName=Angular.ng-template)

## Why It's Useful

The Angular Language Service bridges the gap between your component's TypeScript class and its HTML template. It provides a level of integration and error-checking that is otherwise impossible in the template files.

-   **Type Checking in Templates:** It understands your component's properties and methods, allowing it to catch typos and type errors directly in your HTML.
-   **Autocompletion:** It provides rich IntelliSense and autocompletion for bindings, component properties, and event handlers inside your templates.
-   **Go to Definition:** You can right-click on a component or property in your template and select "Go to Definition" to immediately jump to its TypeScript source code.

## Mini-Tutorial

1.  **Install the extension** from the VS Code Marketplace.
2.  **Create a component:**
    ```typescript
    // my-test.component.ts
    @Component({ /* ... */ })
    export class MyTestComponent {
      public pageTitle = 'My Awesome Page';
      public onSave(): void { console.log('Saved!'); }
    }
    ```
3.  **Open the component's template:**
    ```html
    <!-- my-test.component.html -->
    <h1>{{ pa }}</h1>
    <button (click)="onSav()"></button>
    ```
4.  **Observe the Errors:**
    -   **Expected Result:** The Language Service will immediately underline `pa` and `onSav`. Hovering over them will show an error message like "Property 'pa' does not exist on type 'MyTestComponent'".

5.  **Test Autocompletion:**
    -   Delete the incorrect property `pa`.
    -   Inside the `{{ }}`, press `Ctrl+Space`.
    -   **Expected Result:** A dropdown should appear showing the available properties, including `pageTitle`. This confirms the extension is working correctly.

This extension provides a massive productivity boost and helps prevent a whole class of common template errors before you even compile your code.