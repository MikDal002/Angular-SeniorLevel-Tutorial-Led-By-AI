# Lesson 5: Angular Material and Theme Setup

Angular Material is a UI component library that implements Google's Material Design. It provides a set of high-quality, reusable, and accessible UI components. This lesson will show you how to add Angular Material to your project and how to set up a custom theme to ensure a consistent look and feel across your application.

## 1. Add Angular Material

The easiest way to add Angular Material to your project is by using the `ng add` command.

- **Action:** Run the `ng add` command for `@angular/material`.
  ```bash
  ng add @angular/material
  ```
- **Prompts:** The command will prompt you with a few questions:
  - **Choose a prebuilt theme name, or "custom" for a custom theme:** Select **Custom**.
  - **Set up global Angular Material typography styles?** Select **Yes**.
  - **Set up browser animations for Angular Material?** Select **Yes**.
- **What `ng add` does:**
  - Adds the necessary dependencies (`@angular/material`, `@angular/cdk`) to your `package.json`.
  - Adds the Roboto font and Material Icons to your `index.html`.
  - Adds some basic global CSS to `styles.scss`.
  - Creates a `theme.scss` file (or similar) where you can define your custom theme.
- **Resource:** [Getting started with Angular Material](https://material.angular.io/guide/getting-started)

## 2. Create a Custom Theme

A custom theme allows you to define your application's color palette, typography, and component density, ensuring a consistent and branded user experience.

- **Action:** Open the main stylesheet file (usually `src/styles.scss`) and you should see an import for your theme file. The `ng add` schematic should have created a basic custom theme file for you. Let's refine it.

- **Action:** Open the theme file (e.g., `src/theme.scss`) and define your color palettes. A theme in Angular Material is composed of several palettes: `primary`, `accent` (also called `secondary` in the new MDC-based components), and `warn`.

  ```scss
  @use '@angular/material' as mat;

  @include mat.core();

  // Define the palettes for your theme using the Material Design palettes
  // (either a pre-built one, or a custom one).
  $my-app-primary: mat.define-palette(mat.$indigo-palette);
  $my-app-accent: mat.define-palette(mat.$pink-palette, A200, A100, A400);

  // The warn palette is optional (defaults to red).
  $my-app-warn: mat.define-palette(mat.$red-palette);

  // Create the theme object. A theme consists of configurations for individual
  // theming systems (color, typography, and density).
  $my-app-theme: mat.define-light-theme((
    color: (
      primary: $my-app-primary,
      accent: $my-app-accent,
      warn: $my-app-warn,
    )
  ));

  // Apply the theme to your components.
  @include mat.all-component-themes($my-app-theme);
  ```

- **Resource:** [Theming your Angular Material app](https://material.angular.io/guide/theming)
- **Resource:** [Angular Material Components Theming System: Complete Guide](https://material.angular.io/guide/theming-your-components)

## 3. Configure Typography and Density

Beyond colors, you can also customize typography and the density of your components.

### Typography

- **Action:** In your theme file, define a custom typography configuration. You can specify the font family, and scale for different text elements like headlines, body text, and buttons.

  ```scss
  // ... (after defining palettes)

  $my-app-typography: mat.define-typography-config(
    $font-family: 'Roboto, sans-serif',
    $headline-1: mat.define-typography-level(112px, 112px, 300, $letter-spacing: -0.05em),
    // ... other typography levels
  );

  $my-app-theme: mat.define-light-theme((
    color: (
      primary: $my-app-primary,
      accent: $my-app-accent,
      warn: $my-app-warn,
    ),
    typography: $my-app-typography,
    density: 0,
  ));

  // ... (apply theme)
  ```

- **Resource:** [Customizing Typography](https://material.angular.io/guide/typography)

### Density

- **Action:** Adjust the density of your components for a more compact or spacious layout. The density scale ranges from -4 (most dense) to 0 (default).

  ```scss
  // ... (in your theme definition)

  $my-app-theme: mat.define-light-theme((
    color: (
      primary: $my-app-primary,
      accent: $my-app-accent,
      warn: $my-app-warn,
    ),
    typography: $my-app-typography,
    density: -1, // A bit more compact
  ));

  // ... (apply theme)
  ```

- **Resource:** [Customizing Density](https://material.angular.io/guide/density)

## 4. Verify the Setup

To make sure everything is working, let's add a Material component to your `app.component.html`.

- **Action:** In your `app.module.ts` (or the `imports` array of your standalone `AppComponent`), import `MatButtonModule`.
  ```typescript
  import { MatButtonModule } from '@angular/material/button';

  // ... in your imports array
  @NgModule({
    imports: [
      // ...
      MatButtonModule,
    ],
    // ...
  })
  ```
- **Action:** In your `app.component.html`, add a styled button.
  ```html
  <button mat-raised-button color="primary">Primary Button</button>
  <button mat-raised-button color="accent">Accent Button</button>
  <button mat-raised-button color="warn">Warn Button</button>
  ```
- **Action:** Run `ng serve` and you should see three buttons styled with the colors from your custom theme.

With a custom theme, you have full control over the visual identity of your application, ensuring it aligns with your brand while leveraging the power and consistency of Angular Material.