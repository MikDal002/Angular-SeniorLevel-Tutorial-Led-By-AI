# Lesson 1: OpenAPI/NSwag Client Generation

In modern web development, the backend and frontend are often developed by different teams. A contract is needed to ensure they can communicate effectively. The **OpenAPI Specification** (formerly known as Swagger) is the industry standard for defining this contract for REST APIs.

Instead of manually writing `HttpClient` calls and TypeScript interfaces to match the API, we can use tools to **generate a strongly-typed TypeScript client** directly from the OpenAPI specification. This has several major advantages:

-   **Saves Time:** Eliminates the tedious and error-prone work of manually creating data models and HTTP service calls.
-   **Reduces Bugs:** The generated client is strongly typed, so the TypeScript compiler can catch mismatches between the frontend and the API contract at build time.
-   **Stays in Sync:** When the API changes, you simply regenerate the client to get all the new endpoints and model updates.

**NSwag** is a popular toolchain that can consume an OpenAPI specification and generate client code for various languages, including TypeScript for Angular.

- **Resource:** [Get started with NSwag and ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/tutorials/getting-started-with-nswag?view=aspnetcore-8.0) (The concepts apply even if your backend isn't ASP.NET Core).
- **Resource:** [Streamlining Angular Development: Generating Client-Side Code with NSwag Studio](https://medium.com/@robertban/streamlining-angular-development-generating-client-side-code-with-nswag-studio-and-openapi-8d8550fb4029)

## The Generation Workflow

The typical workflow involves using **NSwagStudio**, a Windows desktop application that provides a GUI for configuring and generating the client.

### Step 1: Get the OpenAPI Specification

First, you need the URL of the OpenAPI specification document, which is usually a JSON or YAML file hosted by the backend server (e.g., `https://api.example.com/swagger/v1/swagger.json`).

### Step 2: Configure NSwagStudio

1.  **Download and run NSwagStudio.** You can find the latest release on the [NSwag GitHub repository](https://github.com/RicoSuter/NSwag/releases).
2.  In the "Swagger Specification" input, paste the URL to your `swagger.json` file.
3.  Click "Create local Copy" to fetch the specification.
4.  Check the "TypeScript Client" box on the right. This will open up the configuration options for the generated client.

### Step 3: Key TypeScript Client Settings

-   **Template:** Choose `Angular`. This generates a client that uses Angular's `HttpClient` and `Injectable` services.
-   **Module name & Module name:** You can leave these blank for a simple, non-module setup.
-   **Injection Token:** Specify `InjectionToken` for the `API_BASE_URL`. This allows you to easily provide the base URL of your API in your application's configuration.
-   **Use `fetch`:** Uncheck this. We want to use Angular's `HttpClient`.
-   **RxJs Version:** Ensure this matches the version used in your project.
-   **Output path:** Specify where the generated file should be saved (e.g., `src/app/shared/api/generated-client.ts`).

![NSwagStudio Configuration Screenshot](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*5Y5j8Z9Q9Y7C5L3k4jG0fA.png)
*(Image credit: Robert Ban)*

### Step 4: Generate the Client

Click the "Generate Files" button. NSwagStudio will create a single TypeScript file at your specified output path. This file will contain:
-   Interfaces for all your API's data transfer objects (DTOs).
-   An injectable service class for each API controller.
-   Methods on each service for every API endpoint, with strong typing for all parameters and return values.

### Step 5: Integrate into Your Angular App

1.  **Provide the Base URL:** In your `app.config.ts`, provide the base URL for the generated client using the `API_BASE_URL` injection token.

    ```typescript
    // app.config.ts
    import { API_BASE_URL } from './shared/api/generated-client';
    import { environment } from '../environments/environment';

    export const appConfig: ApplicationConfig = {
      providers: [
        { provide: API_BASE_URL, useValue: environment.apiUrl },
        // ... other providers
      ],
    };
    ```

2.  **Use the Generated Service:** You can now inject and use the generated service in your components, effects, or other services.

    ```typescript
    // some.component.ts
    import { Component, inject } from '@angular/core';
    import { ProductsClient, ProductDto } from './shared/api/generated-client.ts';

    @Component({ /* ... */ })
    export class SomeComponent {
      private productsClient = inject(ProductsClient);

      products$ = this.productsClient.getAll(); // Returns an Observable<ProductDto[]>

      createProduct() {
        const newProduct = new ProductDto({ name: 'New Product', price: 99.99 });
        this.productsClient.create(newProduct).subscribe();
      }
    }
    ```

## Automating Regeneration

For a real project, you don't want to run NSwagStudio manually every time the API changes. NSwagStudio allows you to save your configuration as an `.nswag` file. This file can be checked into source control and used with the NSwag command-line interface (CLI) to automate the generation process as part of your build pipeline or with a simple `npm` script.

```json
// package.json
"scripts": {
  "generate-api": "nswag run my-api.nswag /runtime:Net70"
}
```
- **Resource:** [Generate code with NSwag using the OpenAPI Specification](https://timdeschryver.dev/bits/generate-code-with-nswag-using-the-openapi-specification)

By leveraging code generation, you create a more robust and efficient development workflow, allowing you to focus on building features instead of writing boilerplate data access code.