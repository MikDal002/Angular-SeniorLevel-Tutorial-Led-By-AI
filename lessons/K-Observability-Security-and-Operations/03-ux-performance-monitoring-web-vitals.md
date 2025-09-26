# Lesson 3: UX Performance Monitoring (Web Vitals)

Good performance is not just about fast servers or small bundles; it's about the user's *perceived* experience. Google has standardized how we measure this experience with a set of metrics called **Core Web Vitals**. Monitoring and optimizing for these vitals is crucial for user satisfaction and can also impact your site's SEO ranking.

- **Resource:** [Understanding Core Web Vitals (Google Search Central)](https://developers.google.com/search/docs/appearance/core-web-vitals)

## What are the Core Web Vitals?

There are three key metrics that measure different aspects of the user's experience:

1.  **Largest Contentful Paint (LCP):** *Loading Performance.*
    -   **What it measures:** The time it takes for the largest image or text block within the user's viewport to become visible.
    -   **Goal:** Below 2.5 seconds.
    -   **What it means:** "How quickly can I see the most important content on this page?"

2.  **Interaction to Next Paint (INP):** *Responsiveness.*
    -   **What it measures:** The latency of all interactions a user has with a page, reporting a single value which most interactions exceeded. A low INP means the page was consistently responsive.
    -   **Goal:** Below 200 milliseconds.
    -   **What it means:** "When I click, tap, or type, does the page react quickly?"
    -   *Note: INP replaced First Input Delay (FID) as a Core Web Vital in March 2024.*

3.  **Cumulative Layout Shift (CLS):** *Visual Stability.*
    -   **What it measures:** The sum total of all unexpected layout shifts that occur during the page's lifespan. A layout shift is when a visible element changes its position.
    -   **Goal:** A score below 0.1.
    -   **What it means:** "Does the content jump around unexpectedly as the page loads?" This is often caused by ads, images, or iframes loading without reserved space.

## How to Measure Web Vitals: Real User Monitoring (RUM)

You can measure Web Vitals on your own machine using tools like Lighthouse in Chrome DevTools. This is called "lab" testing. However, to understand how your application performs for *real users* on different devices and network conditions, you need **Real User Monitoring (RUM)**.

This involves integrating a third-party observability service into your application that collects performance data from your users' browsers and aggregates it for you to analyze.

## Implementing Web Vitals Monitoring with Sentry

Many observability platforms, like Sentry, Datadog, or New Relic, have built-in support for Web Vitals. The process is often as simple as enabling their performance monitoring features.

Let's use Sentry as an example.

### 1. Enable Performance Tracing

In your `main.ts` file where you initialize Sentry, you need to configure `tracesSampleRate` or `tracesSampler`. This tells Sentry what percentage of user sessions should be monitored for performance.

You also need to add the `BrowserTracing` integration.

```typescript
// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';
import * as Sentry from "@sentry/angular";

Sentry.init({
  dsn: "YOUR_SENTRY_DSN_HERE",

  // Add the BrowserTracing integration
  integrations: [
    Sentry.browserTracingIntegration(),
  ],

  // Set tracesSampleRate to 1.0 to capture 100%
  // of transactions for performance monitoring.
  // In production, you may want to lower this value (e.g., 0.1 for 10%).
  tracesSampleRate: 1.0,
});

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => console.error(err));
```

### 2. That's It!

Once the Sentry SDK is initialized with performance monitoring enabled, it will **automatically** measure the Core Web Vitals for each page navigation in your SPA.

-   The SDK listens for page loads and route changes.
-   It captures LCP, INP, and CLS metrics for that "transaction."
-   It sends this data to Sentry, where it is aggregated and visualized.

### 3. Analyzing the Data in Sentry

In your Sentry dashboard, you can navigate to the "Performance" section. Here you will find:
-   An overview of your application's performance scores.
-   Breakdowns of how each Web Vital is contributing to the score.
-   Detailed transaction views that show you which pages or components are performing poorly.
-   Graphs showing how your vitals are trending over time, allowing you to see if a recent deployment caused a performance regression.

- **Resource:** [Sentry Documentation: Web Vitals](https://docs.sentry.io/product/insights/frontend/web-vitals/)

By integrating a RUM tool to monitor your Core Web Vitals, you move from guessing about performance to making data-driven decisions. You can identify real user-facing performance issues, prioritize optimizations, and ensure your application remains fast and responsive as it evolves.