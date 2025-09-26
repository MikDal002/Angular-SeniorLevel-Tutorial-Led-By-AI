# Lesson 3: Deferrable Views and Progressive Rendering

Traditionally, lazy loading in Angular has been tied to the router. You could only lazy load code for an entire route. With the introduction of **Deferrable Views (`@defer`)**, Angular now provides a powerful, declarative way to lazy load and progressively render specific parts of a component's *template*.

This allows for more fine-grained performance optimizations, enabling you to defer non-critical, heavy, or below-the-fold components until they are actually needed.

- **Resource:** [Official Angular Deferrable Views Guide](https://angular.dev/guide/templates/defer)
- **Resource:** [Angular @defer: Complete Guide by Angular University](https://blog.angular-university.io/angular-defer/)

## How `@defer` Works

You use `@defer` as a block in your component's template. Any components, directives, or pipes used exclusively inside this block will be compiled into a separate JavaScript chunk and will not be included in the application's initial bundle.

```html
<!-- This component is part of the initial bundle -->
<app-main-content></app-main-content>

<!-- The LargeChartComponent and its dependencies will be in a separate,
     lazy-loaded chunk. -->
@defer {
  <app-large-chart></app-large-chart>
}
```
By default, the content inside `@defer` is fetched and rendered when the browser becomes idle (using `requestIdleCallback`).

## Placeholder, Loading, and Error Blocks

A user might interact with your page before the deferred content has loaded. `@defer` provides sub-blocks to manage the UI during this process, creating a smooth, progressive rendering experience.

-   `@placeholder`: (Optional) Content that is displayed *before* the deferred loading is triggered. This content is eagerly loaded. You can specify a `minimum` duration to prevent a quick flash of content.
-   `@loading`: (Optional) Content that is displayed *while* the deferred dependencies are being fetched over the network.
-   `@error`: (Optional) Content that is displayed if the deferred loading fails for any reason (e.g., a network error).

**Example with all blocks:**
```html
@defer {
  <app-comments-list></app-comments-list>
} @placeholder (minimum 500ms) {
  <!-- This is shown immediately -->
  <p>Comments section will load shortly...</p>
} @loading (after 100ms; minimum 1s) {
  <!-- If loading takes more than 100ms, show this spinner -->
  <app-spinner></app-spinner>
} @error {
  <!-- If the comments chunk fails to load -->
  <p>Could not load comments. Please try again later.</p>
}
```

## Controlling When Content Loads: Triggers

Instead of relying on the default "idle" trigger, you can specify exactly when the deferred block should load.

-   **`on viewport`**: Triggers when the placeholder enters the user's viewport. Perfect for content that is "below the fold."
    ```html
    @defer (on viewport) { <app-footer /> }
    ```
-   **`on interaction`**: Triggers when the user interacts (clicks or types) with the placeholder element.
    ```html
    @defer (on interaction) { <app-emoji-picker /> }
    @placeholder { <button>Add Emoji</button> }
    ```
-   **`on hover`**: Triggers when the user hovers over the placeholder. Good for pre-loading content you expect the user to click soon.
    ```html
    @defer (on hover) { <app-complex-menu /> }
    @placeholder { <button>Open Menu</button> }
    ```
-   **`on timer()`**: Triggers after a specified duration.
    ```html
    @defer (on timer(5s)) { <app-session-timeout-warning /> }
    ```
-   **`when <condition>`**: The most flexible trigger. It triggers loading when a boolean expression becomes `true`. This is ideal for binding to a signal or an observable.
    ```html
    @defer (when shouldLoadComments()) { <app-comments-list /> }
    ```

You can combine multiple triggers. For example, load a component when it enters the viewport OR when a button is clicked:
```html
@defer (on viewport; on interaction(triggerButton)) {
  <app-heavy-component />
}
@placeholder {
  <div #triggerButton> <!-- Placeholder content --> </div>
}
```

## Prefetching

You can separate the *fetching* of the code from the *rendering* of the component using `prefetch`. This allows you to download the code ahead of time so it's ready instantly when the user needs it.

The `prefetch` keyword uses the same set of triggers.

```html
<!-- The JS for the chart will be fetched when the user hovers over the button.
     The component will only be rendered when they actually click it. -->
@defer (on interaction(chartButton); prefetch on hover(chartButton)) {
  <app-chart />
}
@placeholder {
  <button #chartButton>Show Chart</button>
}
```

Deferrable views are a game-changer for Angular performance, giving you fine-grained control over your application's bundle size and loading behavior directly within your templates.