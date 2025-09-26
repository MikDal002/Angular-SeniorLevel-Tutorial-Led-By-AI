# Lesson 4: Domain and Adapters (SOLID)

To build a truly scalable and maintainable application, it's not enough to just slice features. We must also be deliberate about how we structure the logic *within* those features. This lesson introduces how to apply **SOLID principles** to isolate your core **domain logic** from external concerns (like APIs and frameworks) using the **Adapter pattern**.

The goal is to create a core application that is independent of the outside world, making it easier to test, maintain, and adapt to change.

## SOLID Principles in a Nutshell

SOLID is a mnemonic acronym for five design principles that help create understandable, flexible, and maintainable software.

-   **S** - **Single Responsibility Principle (SRP):** A class (or component, service, etc.) should have only one reason to change. In Angular, this means a component should focus on presentation, and a service should focus on a single piece of business logic.
-   **O** - **Open/Closed Principle (OCP):** Software entities should be open for extension, but closed for modification. You should be able to add new functionality without changing existing code.
-   **L** - **Liskov Substitution Principle (LSP):** Subtypes must be substitutable for their base types. If you have a `BaseService`, any `ChildService` that extends it should work in its place without causing issues.
-   **I** - **Interface Segregation Principle (ISP):** Clients should not be forced to depend on interfaces they do not use. It's better to have many small, specific interfaces than one large, general-purpose one.
-   **D** - **Dependency Inversion Principle (DIP):** High-level modules should not depend on low-level modules. Both should depend on abstractions. Low-level modules should not depend on high-level modules. Both should depend on abstractions.

- **Resource:** [Mastering SOLID Principles in Angular](https://www.syncfusion.com/blogs/post/angular-solid-principles/amp)
- **Resource:** [Angular and SOLID Principles](https://angular.love/angular-and-solid-principles/)

## Isolating the Domain Logic

The "domain" is the heart of your application—the pure business logic and rules that define what your application *does*. This logic should be completely independent of any framework or external service. It shouldn't know about Angular, HTTP, or how the data is displayed.

In a Feature-Sliced Design (FSD) architecture, the domain logic for a particular entity (e.g., `User`) resides in the `entities/user/model` segment.

**Why is this important?**
-   **Testability:** You can test your core business rules without needing to bootstrap an Angular testing environment or mock `HttpClient`.
-   **Portability:** You could, in theory, take your domain logic and reuse it in a different framework or even a backend service.
-   **Maintainability:** When the core logic is pure and isolated, it's much easier to reason about and change without unintended side effects.

- **Resource:** [Sustainable Angular Architectures with Tactical DDD](https://dev.to/angular/sustainable-angular-architectures-with-tactical-ddd-and-monorepos-c61)

## The Adapter Pattern: Bridging the Gap

So, if the domain logic is isolated, how does it get the data it needs from the outside world (like a REST API)? This is where the **Adapter Pattern** comes in.

An Adapter is a structural design pattern that allows objects with incompatible interfaces to collaborate. In our case, it acts as a bridge between the external world (the API) and our internal domain model.

This directly applies the **Dependency Inversion Principle**. Our high-level domain logic doesn't depend on the low-level `HttpClient`. Instead, both depend on an abstraction (an interface or an abstract class).

### Example: A User Service

Let's design a system to fetch a user.

**1. Define the Abstraction (the "Port")**

First, we define an abstract class in our domain layer that describes what we need: a way to get a user by their ID. This is our "port".

```typescript
// src/entities/user/model/user-data.service.ts
import { Observable } from 'rxjs';
import { User } from './user.model';

export abstract class UserDataService {
  abstract getUserById(id: string): Observable<User>;
}
```
Our domain logic will only ever know about `UserDataService`. It doesn't know or care how it's implemented.

**2. Create the Implementation (the "Adapter")**

Next, we create a concrete implementation of this service. This is our "adapter". It knows about the specific API endpoint and how to map the raw API response to our clean `User` domain model. This adapter would typically live in a `data-access` or `api` segment.

```typescript
// src/entities/user/api/user-api.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { UserDataService } from '../model/user-data.service';
import { User } from '../model/user.model';

interface UserApiResponse {
  uuid: string;
  first_name: string;
  email_address: string;
}

@Injectable({ providedIn: 'root' })
export class UserApiService extends UserDataService {
  constructor(private http: HttpClient) {
    super();
  }

  getUserById(id: string): Observable<User> {
    return this.http.get<UserApiResponse>(`/api/users/${id}`).pipe(
      map(response => ({
        // The adapter's job is to map the external model to our internal one.
        id: response.uuid,
        name: response.first_name,
        email: response.email_address,
      }))
    );
  }
}
```

**3. Provide the Implementation**

Finally, in our `app.config.ts` or a feature module, we tell Angular's dependency injector to use `UserApiService` whenever something asks for `UserDataService`.

```typescript
// src/app/app.config.ts
import { UserDataService } from '../entities/user/model/user-data.service';
import { UserApiService } from '../entities/user/api/user-api.service';

export const appConfig: ApplicationConfig = {
  providers: [
    { provide: UserDataService, useClass: UserApiService },
    // ... other providers
  ],
};
```

### Benefits of this Approach

-   **Decoupling:** Your domain logic is completely decoupled from the API. If the API changes (e.g., `first_name` becomes `firstName`), you only need to update the adapter (`UserApiService`). The rest of your application is unaffected.
-   **Testability:** You can easily test your domain logic by creating a mock implementation of `UserDataService` that returns fake data, without needing `HttpClientModule`.
-   **Flexibility:** If you need to switch data sources (e.g., from a REST API to Firebase or local storage), you just create a new adapter (`UserFirebaseService`) and change a single line in your dependency injection configuration.

By combining SOLID principles with patterns like the Adapter, you can create a clean, robust, and highly maintainable Angular architecture where business logic is safely isolated from the complexities of the outside world.

- **Resource:** [Adapter in TypeScript - Refactoring.Guru](https://refactoring.guru/design-patterns/adapter/typescript/example)
- **Resource:** [Streamlining Data Flow in Angular: The Power of the Adapter Pattern](https://dev.to/bndf1/streamlining-data-flow-in-angular-the-power-of-the-adapter-pattern-1804)