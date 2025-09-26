# Lesson 1: Feature-Sliced Structure

As applications grow, maintaining a clear and scalable project structure becomes critical. A well-organized architecture makes it easier to find code, understand dependencies, and add new features without introducing bugs. Feature-Sliced Design (FSD) is an architectural methodology that organizes code by business domain (features) rather than technical role (e.g., `components`, `services`, `pipes`).

This lesson introduces the core concepts of FSD and how to apply them to an Angular project.

## Core Concepts of Feature-Sliced Design

FSD structures an application into a hierarchy of layers. Each layer has a specific purpose and rules about how it can interact with other layers. The layers, from top to bottom, are:

1.  **`app`**: The top-level layer that initializes the application, including routing, store setup, and global styles.
2.  **`pages`**: Represents a complete page of the application (e.g., a user profile page, a product details page). A page is composed of features and widgets.
3.  **`widgets`**: A composition of features and entities that forms a standalone block of the UI (e.g., a user profile header, a product recommendations list).
4.  **`features`**: Represents a piece of user-facing functionality (e.g., "add to cart", "subscribe to newsletter"). This is where business logic lives.
5.  **`entities`**: Represents a business entity (e.g., `User`, `Product`, `Order`). This layer contains the data model and the UI components needed to display it.
6.  **`shared`**: The lowest layer, containing reusable code that has no business logic. This includes UI kits, utility functions, and application-wide configuration.

The key rule of FSD is that a layer can only depend on layers below it. For example, a `feature` can use an `entity`, but an `entity` cannot know about any `feature`.

- **Resource:** [Feature-Sliced Design Official Documentation](https://feature-sliced.design/)
- **Resource:** [Feature-Sliced Design and good frontend architecture](https://www.codecentric.de/en/knowledge-hub/blog/feature-sliced-design-and-good-frontend-architecture)

## Implementing a Feature-Sliced Structure in Angular

Let's see how this translates to a typical Angular project structure.

```
src/
├── app/
│   ├── app.config.ts
│   ├── app.routes.ts
│   └── ...
├── pages/
│   ├── user-profile/
│   └── product-details/
├── widgets/
│   ├── user-header/
│   └── product-list/
├── features/
│   ├── add-to-cart/
│   └── user-login/
├── entities/
│   ├── user/
│   │   ├── model/ (interfaces, services)
│   │   └── ui/ (components, directives)
│   └── product/
│       ├── model/
│       └── ui/
└── shared/
    ├── api/ (http clients, interceptors)
    ├── config/ (environment variables)
    ├── lib/ (utility functions)
    └── ui/ (button, input, card components)
```

### Slices and Segments

Within each layer (except `app`), the code is organized into **slices**. A slice is a folder that groups code by business domain. For example, in the `entities` layer, you might have a `user` slice and a `product` slice.

Inside each slice, the code is further divided into **segments**. Common segments include:
-   **`model`**: Contains the business logic, data transfer objects (DTOs), and state management (e.g., services, NgRx stores).
-   **`ui`**: Contains the UI components, directives, and pipes.
-   **`lib`**: Contains utility functions specific to the slice.
-   **`api`**: Contains the code for interacting with a specific API endpoint.

This structure keeps all the code related to a single feature or entity co-located, making it easy to work on a specific part of the application in isolation.

### Enforcing Architectural Boundaries

To prevent violations of the FSD rules (e.g., an `entity` importing a `feature`), you can use ESLint rules. The `eslint-plugin-import` package can be configured to restrict imports between layers.

- **Example ESLint Rule:**
  ```javascript
  // .eslintrc.json
  {
    "rules": {
      "import/no-restricted-paths": [
        "error",
        {
          "zones": [
            { "target": "./src/shared", "from": "./src/(app|pages|widgets|features|entities)" },
            { "target": "./src/entities", "from": "./src/(app|pages|widgets|features)" },
            // ... and so on for other layers
          ]
        }
      ]
    }
  }
  ```

## Benefits of Feature-Sliced Design

-   **Scalability:** The modular structure makes it easy to add new features without affecting existing ones.
-   **Maintainability:** Code is easy to find and understand because it's organized by business domain.
-   **Testability:** Features and entities can be tested in isolation.
-   **Team Collaboration:** Different teams can work on different features concurrently with fewer merge conflicts.

- **Example Project:** [Angular Feature Sliced V2 Architecture example](https://github.com/Affiction/angular-feature-sliced)

By adopting a Feature-Sliced structure, you can build large-scale Angular applications that are robust, maintainable, and a pleasure to work on.