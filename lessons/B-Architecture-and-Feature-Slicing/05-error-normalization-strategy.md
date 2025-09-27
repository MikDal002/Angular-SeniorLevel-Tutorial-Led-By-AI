# Lesson 5: Error Normalization Strategy

In a large application, errors can come from many sources: `HttpErrorResponse` from the backend, client-side validation errors, unexpected `Error` objects from third-party libraries, or custom business logic exceptions. Handling each of these differently in your UI components leads to inconsistent user experiences and duplicated code.

An **error normalization strategy** is a pattern for transforming any incoming error into a standardized, predictable format. This normalized error object can then be easily consumed by UI components, notification services, and logging systems.

This lesson builds on the concepts of the `GlobalErrorHandler` and provides a structured way to manage errors gracefully.

## 1. Define a Normalized Error Model

The first step is to define a consistent shape for what an error looks like inside your application. This model should contain everything you need to log the error for developers and display a friendly message to users.

- **Action:** Create an `AppError` interface in your `shared/lib` or `shared/model` directory.

- **Example `app-error.model.ts`:**
  ```typescript
  // src/shared/model/app-error.model.ts
  export interface AppError {
    /** A unique code for the error, useful for i18n or specific UI logic. */
    code: string;
    /** A user-friendly message to be displayed in the UI. */
    userMessage: string;
    /** The original error object, for logging and debugging. */
    originalError: any;
  }
  ```

## 2. Create an Error Normalization Service

Next, create a service whose sole responsibility is to take any kind of error and map it to an `AppError`. This service will contain the logic to inspect the incoming error and determine the appropriate `code` and `userMessage`.

- **Action:** Create an `error-normalization.service.ts`.

- **Example `ErrorNormalizationService`:**
  ```typescript
  // src/shared/lib/error-normalization.service.ts
  import { Injectable } from '@angular/core';
  import { HttpErrorResponse } from '@angular/common/http';
  import { AppError } from '../model/app-error.model';

  @Injectable({ providedIn: 'root' })
  export class ErrorNormalizationService {
    normalize(error: any): AppError {
      if (error instanceof HttpErrorResponse) {
        return this.fromHttpErrorResponse(error);
      }
      // Add more mappers here for different error types
      // else if (error instanceof MyCustomValidationError) { ... }
      else {
        return this.fromUnknownError(error);
      }
    }

    private fromHttpErrorResponse(error: HttpErrorResponse): AppError {
      const code = `HTTP_${error.status}`;
      let userMessage = 'An unexpected error occurred.';

      switch (error.status) {
        case 400:
          userMessage = 'The server could not process the request due to a client error.';
          break;
        case 401:
          userMessage = 'You are not authorized to perform this action.';
          break;
        case 404:
          userMessage = 'The requested resource could not be found.';
          break;
        case 500:
          userMessage = 'A server error occurred. Please try again later.';
          break;
      }

      // You could also try to parse a specific error structure from the response body
      // if (error.error?.message) {
      //   userMessage = error.error.message;
      // }

      return { code, userMessage, originalError: error };
    }

    private fromUnknownError(error: any): AppError {
      return {
        code: 'UNKNOWN_CLIENT_ERROR',
        userMessage: 'An unexpected client-side error occurred.',
        originalError: error,
      };
    }
  }
  ```

## 3. Integrate with the Global Error Handler

Now, update the `GlobalErrorHandler` from the previous lesson to use the `ErrorNormalizationService`. The `GlobalErrorHandler`'s job is no longer to interpret the error, but simply to pass it to the normalization service and then dispatch the normalized error to other services (like logging and notifications).

- **Action:** Inject `ErrorNormalizationService`, `LoggingService`, and a `NotificationService` into your `GlobalErrorHandler`.

- **Example `GlobalErrorHandler`:**
  ```typescript
  // src/shared/lib/global-error-handler.ts
  import { ErrorHandler, Injectable, Injector } from '@angular/core';
  import { ErrorNormalizationService } from './error-normalization.service';
  import { LoggingService } from './logging.service';
  import { NotificationService } from '../ui/notification.service'; // A hypothetical UI service

  @Injectable()
  export class GlobalErrorHandler implements ErrorHandler {
    constructor(private injector: Injector) {}

    handleError(error: any) {
      const normalizer = this.injector.get(ErrorNormalizationService);
      const logger = this.injector.get(LoggingService);
      const notifier = this.injector.get(NotificationService);

      const appError = normalizer.normalize(error);

      // 1. Log the detailed error for developers
      logger.error(`Error Code: ${appError.code}`, appError.originalError);

      // 2. Show a friendly message to the user
      notifier.showError(appError.userMessage);

      // You can still log the original error to the console during development
      console.error(error);
    }
  }
  ```

## 4. Handling Errors in Components (Optional)

Most errors should be handled globally. However, sometimes a component needs to react specifically to an error (e.g., to display an error message next to a form field). In these cases, you can inject the `ErrorNormalizationService` directly into your component.

- **Example in a component:**
  ```typescript
  // my-component.ts
  import { Component } from '@angular/core';
  import { MyService } from './my.service';
  import { ErrorNormalizationService } from 'src/shared/lib/error-normalization.service';
  import { AppError } from 'src/shared/model/app-error.model';
  import { catchError, of } from 'rxjs';

  @Component({ /* ... */ })
  export class MyComponent {
    error: AppError | null = null;

    constructor(
      private myService: MyService,
      private errorNormalizer: ErrorNormalizationService
    ) {}

    doSomething() {
      this.myService.doSomethingThatMightFail().pipe(
        catchError(err => {
          this.error = this.errorNormalizer.normalize(err);
          // Return an empty observable or a default value
          return of(null);
        })
      ).subscribe();
    }
  }
  ```
  The component's template can then bind to `error.userMessage` to display the error inline.

### Benefits of This Strategy

-   **Consistency:** All errors, regardless of their source, are handled in a uniform way.
-   **Decoupling:** UI components don't need to know about `HttpErrorResponse` or other complex error types. They only need to know how to display an `AppError`.
-   **Maintainability:** If the backend error format changes, you only need to update the `fromHttpErrorResponse` method in the `ErrorNormalizationService`. The rest of the application is unaffected.
-   **User Experience:** You can provide clear, helpful, and consistent error messages to your users, improving their overall experience.

---

## ✅ Verifiable Outcome

After implementing this strategy, you can verify its functionality by triggering different types of errors.

1.  **Implement the Services:**
    -   Create the `AppError` model, the `ErrorNormalizationService`, and integrate it into your `GlobalErrorHandler`.
    -   Create a mock `NotificationService` that can display a message (e.g., using `alert()` or by updating a property on a shared service that a component displays).

2.  **Test a Client-Side Error:**
    -   In a component, create a button with a click handler that throws a new `Error('Test client error')`.
    -   Run the application and click the button.
    -   **Expected Result:** An alert or notification should appear with the user-friendly message "An unexpected client-side error occurred." The developer console should show the detailed log from your `GlobalErrorHandler`.

3.  **Test an HTTP Error:**
    -   In a component, create a button that triggers an `HttpClient` call to a non-existent API endpoint (e.g., `/api/does-not-exist`).
    -   Run the application and click the button.
    -   **Expected Result:** Because the request will result in a 404, an alert or notification should appear with the user-friendly message "The requested resource could not be found." The console should show the detailed `HTTP_404` log from your `GlobalErrorHandler`. This verifies that your normalization service is correctly identifying and mapping `HttpErrorResponse` instances.