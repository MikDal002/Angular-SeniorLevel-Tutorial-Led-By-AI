# Lesson 1: Centralized Logging and Global Error Handling

In a production application, `console.log` and `console.error` are not enough. When an error occurs for a real user, you need that error to be sent to a **centralized logging service** so your development team can be alerted, and can analyze, debug, and resolve the issue.

This lesson covers how to use Angular's `ErrorHandler` to intercept all uncaught exceptions and forward them to a third-party logging service, using Sentry as a practical example.

- **Resource:** [Sentry Documentation: Angular Error Handler](https://docs.sentry.io/platforms/javascript/guides/angular/features/error-handler/)
- **Resource:** [Angular `ErrorHandler` API Documentation](https://angular.dev/api/core/ErrorHandler)

## The Role of the Global `ErrorHandler`

As we've covered in previous lessons, you can provide a custom class that implements the `ErrorHandler` interface. This class's `handleError` method will be called for any uncaught exception in your application, whether it's a client-side error or an unhandled `HttpErrorResponse`.

This makes the `ErrorHandler` the perfect "collection point" for all critical errors that need to be logged externally.

## Integrating a Third-Party Logging Service

Most modern logging services (like Sentry, LogRocket, Datadog, etc.) provide an Angular integration that makes this process very simple. They typically ask you to do two things:

1.  **Initialize the service** in your `main.ts` file. This sets up the connection to their backend.
2.  **Provide their custom `ErrorHandler`** in your `app.config.ts`. This replaces Angular's default error handler with one that knows how to send errors to their service.

### Example: Integrating Sentry

**1. Initialize Sentry**
In your `main.ts`, you would initialize Sentry with your project's unique key (DSN).

```typescript
// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';
import * as Sentry from "@sentry/angular";

// Initialize Sentry
Sentry.init({
  dsn: "YOUR_SENTRY_DSN_HERE",
  // ... other configuration like tracesSampleRate
});

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => console.error(err));
```

**2. Provide the Sentry `ErrorHandler`**
Sentry provides a convenient `createErrorHandler` function that creates an `ErrorHandler` instance for you.

```typescript
// app.config.ts
import { ApplicationConfig, ErrorHandler } from '@angular/core';
import * as Sentry from "@sentry/angular";

export const appConfig: ApplicationConfig = {
  providers: [
    // ... other providers
    {
      provide: ErrorHandler,
      useValue: Sentry.createErrorHandler({
        showDialog: true, // Optionally show a Sentry dialog on error
      }),
    },
  ],
};
```
With just these two changes, all uncaught exceptions in your application will now be automatically captured and sent to your Sentry dashboard.

## Extending the Error Handler for Custom Logic

What if you want to perform your own logic *in addition* to sending the error to Sentry? For example, you might want to show a custom notification to the user or log additional context.

You can't provide multiple `ErrorHandler` classes, so the solution is to **extend** the handler provided by the third-party service.

### Example: A Custom Sentry Error Handler

```typescript
// custom-sentry-error-handler.ts
import { ErrorHandler, Injectable, inject } from '@angular/core';
import * as Sentry from '@sentry/angular';
import { NotificationService } from './notification.service'; // Your custom UI notification service

@Injectable()
export class CustomSentryErrorHandler implements ErrorHandler {
  private notificationService = inject(NotificationService);
  private sentryErrorHandler = Sentry.createErrorHandler(); // Create an instance of the Sentry handler

  handleError(error: any) {
    try {
      // 1. First, send the error to Sentry.
      this.sentryErrorHandler.handleError(error);

      // 2. Then, perform your custom logic.
      // This could be showing a user-friendly toast message.
      this.notificationService.showError(
        'An unexpected error occurred. Our team has been notified.'
      );
    } catch (e) {
      console.error('Error in CustomSentryErrorHandler:', e);
      console.error('Original error:', error);
    }
  }
}
```

Now, you provide your custom class in `app.config.ts` instead of Sentry's.

```typescript
// app.config.ts
import { CustomSentryErrorHandler } from './custom-sentry-error-handler';

export const appConfig: ApplicationConfig = {
  providers: [
    // ...
    { provide: ErrorHandler, useClass: CustomSentryErrorHandler },
  ],
};
```
This pattern gives you the best of both worlds: robust, automated error reporting from a professional service, combined with the flexibility to implement custom, application-specific error handling logic and user feedback.