# Lesson 5: Performance Budgets and Bundle Analysis

Good performance is a feature. As an application grows, it's easy for bundle sizes to creep up, leading to slower load times and a worse user experience. Two key practices for maintaining performance are setting **performance budgets** and periodically **analyzing your bundles**.

## 1. Performance Budgets

A performance budget is a set of limits that you define for the size of your application's bundles. The Angular CLI can enforce these budgets, warning you or even failing the build if a bundle exceeds its limit. This acts as an early warning system, preventing performance regressions from being accidentally introduced.

- **Resource:** [Performance budgets with the Angular CLI](https://web.dev/articles/performance-budgets-with-the-angular-cli)

### How to Configure Budgets

You configure performance budgets in your `angular.json` file, typically for your production configuration.

```json
// angular.json
{
  ...
  "projects": {
    "my-app": {
      ...
      "architect": {
        "build": {
          "configurations": {
            "production": {
              ...
              "budgets": [
                {
                  "type": "initial",
                  "maximumWarning": "500kb",
                  "maximumError": "1mb"
                },
                {
                  "type": "anyComponentStyle",
                  "maximumWarning": "2kb",
                  "maximumError": "4kb"
                }
              ]
            }
          }
        }
      }
    }
  }
}
```

### Budget Types

-   **`initial`**: The size of the main JavaScript bundle that's loaded on the first page load. This is the most critical budget to monitor.
-   **`bundle`**: The size of a specific lazy-loaded bundle.
-   **`anyComponentStyle`**: The size of any single component's CSS. This helps catch when a component's styles become excessively large.
-   **`all`**: The total size of the entire application.
-   **`any`**: The size of any single output file.

### How it Works

When you run a production build (`ng build`), the CLI will check the size of the output files against your configured budgets.
-   If a `maximumWarning` is exceeded, you will see a warning in the console. The build will still pass.
-   If a `maximumError` is exceeded, the build will fail.

This forces you to address the size increase before it gets deployed, helping to maintain a high level of performance over the long term.

## 2. Bundle Analysis with `webpack-bundle-analyzer`

When a budget is exceeded, or when you simply want to be proactive about performance, you need to understand what's *inside* your bundles. Why is `main.js` so large? Which libraries are taking up the most space?

`webpack-bundle-analyzer` is a tool that reads the output of a webpack build and creates an interactive treemap visualization of your bundles, showing you exactly what's inside and how much space each module occupies.

- **Resource:** [How To Use webpack-bundle-analyzer for Angular Apps](https://www.digitalocean.com/community/tutorials/angular-angular-webpack-bundle-analyzer)

### How to Use It

**1. Install the package:**
```bash
npm install webpack-bundle-analyzer --save-dev
```

**2. Add a script to `package.json`:**
The easiest way to use the analyzer is to add a script to your `package.json` that first builds your app with the `--stats-json` flag and then runs the analyzer on the generated `stats.json` file.

```json
// package.json
{
  "name": "my-app",
  "version": "0.0.0",
  "scripts": {
    "ng": "ng",
    "start": "ng serve",
    "build": "ng build",
    "watch": "ng build --watch --configuration development",
    "test": "ng test",
    "analyze": "ng build --stats-json && webpack-bundle-analyzer ./dist/my-app/stats.json"
  },
  ...
}
```
*(Note: The path to `stats.json` may vary slightly based on your project name and `angular.json` configuration.)*

**3. Run the analysis:**
```bash
npm run analyze
```

This will perform a production build and then open a new tab in your browser with the interactive treemap.

![Webpack Bundle Analyzer Treemap](https://www.digitalocean.com/cdn-cgi/image/w=1200,q=85,f=auto/https:/community-images.digitalocean.com/wVq5kH5J451T1V66zBwU3Z2e)
*(Image credit: DigitalOcean)*

### Interpreting the Results

The treemap allows you to visually identify large dependencies. You can hover over each box to see its size and path. This is invaluable for finding:
-   **Large third-party libraries:** Is a charting or date library much bigger than you realized? Maybe there's a smaller alternative.
-   **Incorrectly imported modules:** Are you accidentally importing all of RxJS or an entire icon library when you only need a small part of it?
-   **Code that should be lazy-loaded:** Do you see a large feature-specific module inside your `main` bundle? That's a prime candidate for lazy loading.

By regularly setting budgets and analyzing your bundles, you can move from reactive performance fixes to a proactive culture of performance maintenance, ensuring your application stays fast and lean as it evolves.