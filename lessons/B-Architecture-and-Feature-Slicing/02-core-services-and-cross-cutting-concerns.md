# Lesson 2: Core Services and Cross-Cutting Concerns

In any large application, there are services and logic that don't belong to a single feature but are required across the entire application. These are known as **cross-cutting concerns**. Centralizing them is key to a clean, maintainable, and scalable architecture.

In a Feature-Sliced Design (FSD) architecture, these concerns are typically placed in the `shared` layer, or sometimes in the `app` layer if they are truly global and initialized only once. This lesson covers how to centralize configuration, HTTP interceptors, error handling, and logging.

## 1. Application Configuration

Your application will likely have configuration that changes between environments (development, staging, production), such as API endpoints or feature flags. A common pattern is to load this configuration when the application starts.

- **Pattern:** Use the `APP_INITIALIZER` token to run a function during application bootstrap. This function can fetch a configuration file (`config.json`) and provide it as a service.

- **Action:**
  1.  Create a `config.service.ts` in `src/shared/config/`.
  2.  This service will have a method to load a `config.json` file via `HttpClient`.
  3.  In your `app.config.ts`, provide a factory function using `APP_INITIALIZER` that calls the load method.

- **Example `config.service.ts`:**
  ```typescript
  // src/shared/config/config.service.ts
  import { Injectable } from '@angular/core';
  import { HttpClient } from '@angular/common/http';
  import { firstValueFrom } from 'rxjs';

  @Injectable({ providedIn: 'root' })
  export class ConfigService {
    private appConfig: any;

    constructor(private http: HttpClient) {}

    loadAppConfig() {
      return firstValueFrom(this.http.get('/assets/config.json'))
        .then(config => {
          this.appConfig = config;
        });
    }

    getConfig() {
      return this.appConfig;
    }
  }
  ```

- **Example `app.config.ts`:**
  ```typescript
  // src/app/app.config.ts
  import { ApplicationConfig, APP_INITIALIZER } from '@angular/core';
  import { ConfigService } from '../shared/config/config.service';

  export function initializeApp(configService: ConfigService) {
    return () => configService.loadAppConfig();
  }

  export const appConfig: ApplicationConfig = {
    providers: [
      {
        provide: APP_INITIALIZER,
        useFactory: initializeApp,
        multi: true,
        deps: [ConfigService],
      },
      // ... other providers
    ],
  };
  ```

- **Resource:** [Building and serving Angular apps - Environments](https://angular.io/guide/build#configuring-application-environments)

## 2. HTTP Interceptors

Interceptors allow you to inspect and transform HTTP requests and responses globally. This is the perfect place to handle tasks like adding authentication tokens, setting headers, or logging HTTP traffic.

- **Pattern:** Create services that implement the `HttpInterceptor` interface. You can have a chain of multiple interceptors.

- **Use Cases:**
  -   **Auth Interceptor:** Attaches a JWT or API key to the `Authorization` header of outgoing requests.
  -   **Logging Interceptor:** Logs request and response details for debugging.
  -   **Error Interceptor:** Catches HTTP errors (4xx, 5xx) and triggers a global error handling mechanism.

- **Example Auth Interceptor:**
  ```typescript
  // src/shared/api/auth.interceptor.ts
  import { Injectable } from '@angular/core';
  import { HttpInterceptor, HttpRequest, HttpHandler } from '@angular/common/http';

  @Injectable()
  export class AuthInterceptor implements HttpInterceptor {
    intercept(req: HttpRequest<any>, next: HttpHandler) {
      const authToken = 'YOUR_AUTH_TOKEN'; // Get this from a service
      const authReq = req.clone({
        headers: req.headers.set('Authorization', `Bearer ${authToken}`)
      });
      return next.handle(authReq);
    }
  }
  ```

- **Providing the Interceptor:**
  ```typescript
  // src/app/app.config.ts
  import { provideHttpClient, withInterceptors } from '@angular/common/http';
  import { authInterceptor } from '../shared/api/auth.interceptor'; // Assuming it's a functional interceptor

  export const appConfig: ApplicationConfig = {
    providers: [
      provideHttpClient(withInterceptors([authInterceptor])),
      // ...
    ],
  };
  ```

- **Resource:** [Intercepting requests and responses](https://angular.io/guide/http-interceptors)

## 3. Global Error Handling

A robust application needs a centralized way to handle unexpected errors, whether they come from the UI, a service, or an HTTP request.

- **Pattern:** Create a custom class that implements `ErrorHandler` and replace Angular's default handler.

- **Action:**
  1.  Create a `global-error-handler.ts` in `src/shared/lib/`.
  2.  In this class, you can inject services like a `LoggingService` or a `NotificationService`.
  3.  You can inspect the error to determine its type (e.g., `HttpErrorResponse` vs. a client-side error) and react accordingly.

- **Example `GlobalErrorHandler`:**
  ```typescript
  // src/shared/lib/global-error-handler.ts
  import { ErrorHandler, Injectable, Injector } from '@angular/core';
  import { HttpErrorResponse } from '@angular/common/http';
  import { LoggingService } from './logging.service'; // Your custom logging service

  @Injectable()
  export class GlobalErrorHandler implements ErrorHandler {
    constructor(private injector: Injector) {}

    handleError(error: Error | HttpErrorResponse) {
      const logger = this.injector.get(LoggingService);
      let message: string;

      if (error instanceof HttpErrorResponse) {
        // Server error
        message = `Server Error: ${error.status} - ${error.message}`;
        logger.error(message, error);
      } else {
        // Client-side error
        message = `Client Error: ${error.message}`;
        logger.error(message, error);
      }

      // Here you could also use a notification service to show a user-friendly message.
      console.error(error); // Keep the default behavior for developers
    }
  }
  ```

- **Providing the Handler:**
  ```typescript
  // src/app/app.config.ts
  import { ErrorHandler } from '@angular/core';
  import { GlobalErrorHandler } from '../shared/lib/global-error-handler';

  export const appConfig: ApplicationConfig = {
    providers: [{ provide: ErrorHandler, useClass: GlobalErrorHandler }],
  };
  ```
- **Resource:** [ErrorHandler API Documentation](https://angular.io/api/core/ErrorHandler)
- **Resource:** [Implementing a Global Error Handler in Angular](https://www.telerik.com/blogs/implementing-global-error-handler-angular-step-guide)

## 4. Logging Service

A dedicated logging service provides a flexible way to manage application logs. You can control the log level, and direct logs to different outputs (e.g., console, a remote logging service) based on the environment.

- **Pattern:** Create a `LoggingService` that can be injected anywhere in the application.

- **Example `LoggingService`:**
  ```typescript
  // src/shared/lib/logging.service.ts
  import { Injectable } from '@angular/core';
  import { environment } from '../../../environments/environment';

  @Injectable({ providedIn: 'root' })
  export class LoggingService {
    log(message: string) {
      if (!environment.production) {
        console.log(message);
      }
    }

    warn(message: string) {
      if (!environment.production) {
        console.warn(message);
      }
    }

    error(message: string, error?: any) {
      // In a real app, you might send this to a logging backend like Sentry or LogRocket
      console.error(message, error);
    }
  }
  ```
- **Resource:** [Adding Logging in Angular Applications](https://www.codemag.com/article/1711021/Logging-in-Angular-Applications)

By centralizing these cross-cutting concerns, you create a more robust and maintainable application. The rest of your code can focus on delivering business value, while these core services handle the technical details consistently.