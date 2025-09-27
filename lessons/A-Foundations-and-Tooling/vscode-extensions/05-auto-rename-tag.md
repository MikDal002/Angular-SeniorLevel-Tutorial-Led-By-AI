# VS Code Extension: Auto Rename Tag

This extension does one simple thing, and it does it perfectly. It's a small productivity boost that saves you from a common and frustrating type of typo in HTML.

- **Marketplace Link:** [Auto Rename Tag](https://marketplace.visualstudio.com/items?itemName=formulahendry.auto-rename-tag)

## Why It's Useful

When you are refactoring or correcting your HTML structure, you often need to change a tag type (e.g., changing a `<div>` to a more semantic `<section>`). By default, you have to change the opening tag (`<div>`) and then manually find and change the corresponding closing tag (`</div>`). Forgetting to do this is a common source of broken layouts.

Auto Rename Tag completely automates this process. When you rename the opening tag, it instantly renames the closing tag to match.

## Mini-Tutorial

1.  **Install the extension** from the VS Code Marketplace. It works out of the box with no configuration required.

2.  **Open an HTML file** in your project.

3.  **Create a Tag Pair:**
    ```html
    <div>
      <p>Some content here.</p>
    </div>
    ```

4.  **Rename the Opening Tag:**
    -   Place your cursor on the opening `div` tag.
    -   Change it to `section`.
    -   **Expected Result:** As you type, the corresponding closing `</div>` tag at the end of the block will automatically change to `</section>`, keeping your HTML valid.

This simple extension prevents countless small errors and makes refactoring your templates faster and more reliable.