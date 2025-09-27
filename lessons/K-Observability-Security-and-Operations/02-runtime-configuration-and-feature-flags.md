# Lesson 2: Runtime Configuration and Feature Flags

The standard Angular CLI `environments` files are great for values that are known at *build time*. However, in many enterprise deployment scenarios, you build your application **once** and then deploy that same build artifact to multiple environments (dev, test, staging, production). Each environment needs a different configuration (e.g., a different API endpoint), but you can't rebuild the app for each one.

The solution is to load configuration at **runtime**. This involves fetching a configuration file when the application first starts up, *before* the main `AppComponent` is rendered. This pattern is also perfect for managing **feature flags**, which allow you to remotely enable or disable features in your application without a redeployment.

- **Resource:** [Angular `APP_INITIALIZER` API Documentation](https://angular.dev/api/core/APP_INITIALIZER)
- **Resource:** [Loading App Configuration in the APP_INITIALIZER by Preston Lamb](https://www.prestonlamb.com/blog/loading-app-config-in-app-initializer/)
- **Resource:** [Dynamic Configuration: Leveraging APP_INITIALIZER](https://angular.love/dynamic-configuration-leveraging-app-initializer/)

## The `APP_INITIALIZER` Pattern

Angular provides a special dependency injection token called `APP_INITIALIZER`. It allows you to register one or more functions that must complete *before* the application initialization process finishes. If a function returns a `Promise` or `Observable`, Angular will wait for it to resolve or complete.

We can use this to create a "blocking" fetch for our runtime configuration file.

### 1. Create the Configuration File

First, create a `config.json` file in your `src/assets` directory. Placing it in `assets` ensures it gets copied to your `dist` folder as-is, without being bundled into your JavaScript.

**`src/assets/config/config.json`**
```json
{
  "apiUrl": "https://api.prod.example.com",
  "featureFlags": {
    "enableNewDashboard": true,
    "enableChatFeature": false
  }
}
```

### 2. Create the Configuration Service

Next, create a service that will be responsible for loading and providing the configuration.

```typescript
// config.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

export interface AppConfig {
  apiUrl: string;
  featureFlags: {
    [key: string]: boolean;
  };
}

@Injectable({ providedIn: 'root' })
export class ConfigService {
  private http = inject(HttpClient);
  private config: AppConfig | undefined;

  // This method will be called by the APP_INITIALIZER
  loadConfig(): Promise<void> {
    return firstValueFrom(this.http.get<AppConfig>('/assets/config/config.json'))
      .then(config => {
        this.config = config;
      })
      .catch(err => {
        console.error('Could not load configuration file. Using default values.', err);
        // You might want to set default values here as a fallback
      });
  }

  // Getter for the API URL
  get apiUrl(): string {
    if (!this.config) {
      throw new Error('Configuration not loaded!');
    }
    return this.config.apiUrl;
  }

  // Getter for checking feature flags
  isFeatureEnabled(flagName: string): boolean {
    if (!this.config) {
      throw new Error('Configuration not loaded!');
    }
    return !!this.config.featureFlags[flagName];
  }
}
```

### 3. Provide the `APP_INITIALIZER`

Finally, wire everything up in your `app.config.ts`. You create a factory function that calls the `loadConfig` method and provide it using the `APP_INITIALIZER` token.

```typescript
// app.config.ts
import { ApplicationConfig, APP_INITIALIZER } from '@angular/core';
import { provideHttpClient } from '@angular/common/http';
import { ConfigService } from './config.service';

// Factory function for the initializer
export function initializeApp(configService: ConfigService) {
  return (): Promise<any> => {
    return configService.loadConfig();
  };
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(), // HttpClient is needed by ConfigService
    ConfigService,
    {
      provide: APP_INITIALIZER,
      // The factory that will be executed
      useFactory: initializeApp,
      // Dependencies that need to be injected into the factory
      deps: [ConfigService],
      // `multi: true` is required because there can be multiple initializers
      multi: true,
    },
  ],
};
```

### 4. Using the Runtime Configuration

Now, you can inject your `ConfigService` anywhere in your application and safely access the configuration values, knowing they have been loaded before the app started.

**Using an API Endpoint:**
```typescript
// some-data.service.ts
@Injectable({ providedIn: 'root' })
export class SomeDataService {
  private apiUrl = inject(ConfigService).apiUrl;
  // ...
}
```

**Using a Feature Flag:**
```typescript
// some.component.html
<div *ngIf="isNewDashboardEnabled()">
  <!-- Show the new dashboard -->
</div>

// some.component.ts
@Component({ /*...*/ })
export class SomeComponent {
  private configService = inject(ConfigService);

  isNewDashboardEnabled(): boolean {
    return this.configService.isFeatureEnabled('enableNewDashboard');
  }
}
```

This pattern provides a robust and flexible way to manage environment-specific configurations and feature flags, allowing you to build and deploy your application once and configure it for any environment at runtime.