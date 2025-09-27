# Lesson 6: Accessibility (a11y) Fundamentals

Web accessibility (often abbreviated as **a11y**) is the practice of ensuring that your websites and applications are usable by everyone, regardless of their abilities or the assistive technology they use. This includes people with visual, auditory, motor, or cognitive disabilities.

Building accessible applications is not just a legal requirement in many places; it's a core part of creating a positive and inclusive user experience. This lesson covers the fundamentals of making your Angular components accessible, focusing on keyboard navigation and screen reader support.

- **Primary Resource:** [Official Angular Accessibility Guide](https://angular.io/guide/accessibility)

## 1. Use Semantic HTML

The easiest and most important step towards accessibility is to use HTML elements for their intended purpose. Semantic HTML provides meaning and structure to your content, which is essential for screen readers.

-   **Use `<button>` for clicks:** Don't use a `<div>` or a `<span>` with a `(click)` handler. A native `<button>` is focusable by default, can be activated with both the Enter key and the Spacebar, and is announced as a "button" by screen readers.
-   **Use `<a>` for navigation:** Use an anchor tag with an `href` attribute for links that navigate the user to a new URL.
-   **Use heading tags (`<h1>`, `<h2>`, etc.) to structure content:** This creates a document outline that screen reader users can use to quickly navigate a page.
-   **Use `<label>` for form inputs:** A `<label>` associated with an `<input>` (via the `for` attribute) ensures that clicking the label focuses the input and that screen readers announce the label when the input is focused.

**Example:**
```html
<!-- BAD: Not accessible -->
<div (click)="save()">Save</div>

<!-- GOOD: Accessible -->
<button (click)="save()">Save</button>
```

## 2. Ensure Keyboard Navigability

All interactive elements in your application must be reachable and operable using only the keyboard.

-   **Focus Order:** The order in which elements receive focus when the user presses the `Tab` key should be logical and predictable. This is usually determined by the element's order in the DOM.
-   **Custom Components:** If you build a custom interactive component (like a custom dropdown or a slider), you must ensure it is focusable. You can do this by setting `tabindex="0"` on the element.
-   **Visible Focus Indicator:** Never disable the focus outline (e.g., with `outline: none;` in your CSS) without providing a clear and visible alternative. Users need to know which element currently has focus.

## 3. Use ARIA Attributes for Dynamic Content

Sometimes, native HTML isn't enough to describe the complex, dynamic widgets found in modern web apps. **Accessible Rich Internet Applications (ARIA)** is a set of attributes you can add to HTML elements to provide additional semantic meaning for screen readers.

-   **Binding to ARIA Attributes:** When you bind to an ARIA attribute in Angular, you must use the `attr.` prefix. This is because ARIA attributes are HTML attributes, not DOM properties.

    ```html
    <!-- Correctly bind to an ARIA attribute -->
    <button [attr.aria-label]="'Close dialog'">X</button>

    <!-- Announce that a region is busy loading data -->
    <div [attr.aria-busy]="isLoading">
      <!-- content -->
    </div>
    ```

-   **Common ARIA Attributes:**
    -   `aria-label`: Provides an accessible name for an element when there is no visible label (e.g., an "X" icon button).
    -   `aria-labelledby`: Associates an element with the ID of another element that serves as its label.
    -   `aria-describedby`: Associates an element with the ID of another element that provides a more detailed description.
    -   `aria-live`: Indicates a region of the page that will be updated dynamically, telling screen readers to announce the changes (e.g., for live chat messages or error notifications).
    -   `role`: Defines the purpose of an element (e.g., `role="dialog"`, `role="tablist"`).

## 4. Leverage the Angular CDK's a11y Tools

The Angular Component Dev Kit (CDK) has a dedicated `a11y` package with tools to help you solve common accessibility challenges.

-   **`LiveAnnouncer`:** A service that allows you to programmatically announce messages to screen reader users from an `aria-live` region. This is perfect for notifications like "Item added to cart."

    ```typescript
    import { LiveAnnouncer } from '@angular/cdk/a11y';

    // in your component
    constructor(private announcer: LiveAnnouncer) {}

    announceSave() {
      this.announcer.announce('Your changes have been saved.');
    }
    ```

-   **`cdkTrapFocus` Directive:** This directive traps the user's focus within an element. It's essential for creating accessible modal dialogs, ensuring that when a dialog is open, the user can only `Tab` between the elements inside it, not the content behind it.

    ```html
    <!-- When the dialog is open, focus will be trapped inside this div -->
    <div class="my-dialog" cdkTrapFocus>
      <!-- dialog content -->
    </div>
    ```

- **Resource:** [Angular CDK Accessibility Overview](https://material.angular.io/cdk/a11y/overview)

---

## ✅ Verifiable Outcome

You can verify these accessibility concepts manually using only your browser and keyboard.

1.  **Test Keyboard Navigation:**
    -   In your application, try to navigate through all interactive elements (links, buttons, form inputs) using only the `Tab` key. Use `Shift+Tab` to navigate backwards.
    -   **Expected Result:** You should be able to reach every single interactive element. The focus order should be logical (e.g., top-to-bottom, left-to-right). There should always be a visible focus indicator (like a blue outline) showing you which element is currently active.

2.  **Test a Custom `cdkTrapFocus` Dialog:**
    -   Implement a simple modal dialog component.
    -   Add the `cdkTrapFocus` directive to the root element of the dialog.
    -   Open the dialog and try to `Tab` through its elements.
    -   **Expected Result:** Your focus should be "trapped" within the dialog. You should be able to cycle through the interactive elements inside the dialog, but you should not be able to `Tab` to the elements on the page behind the dialog.

3.  **Test with a Screen Reader (Basic):**
    -   Most operating systems have a built-in screen reader (e.g., Narrator on Windows, VoiceOver on macOS). Enable it.
    -   Navigate your application using the keyboard.
    -   **Expected Result:** Listen to the announcements. Does the screen reader announce buttons as "button"? Does it read the `aria-label` for icon-only buttons? When you focus an input, does it read the associated `<label>`? This provides direct feedback on how accessible your application is to visually impaired users.