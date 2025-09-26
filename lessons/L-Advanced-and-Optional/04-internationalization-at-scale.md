# Lesson 4: Internationalization (i18n) at Scale

Internationalization (i18n) is the process of designing your application to be adaptable to various languages and regions without engineering changes. For large-scale applications, this means more than just translating text; it means handling different date formats, number formats, and currencies, and doing so in a way that is performant and maintainable.

## Built-in i18n vs. Runtime Libraries

Angular has a built-in i18n solution that is robust and well-integrated. However, it has one major characteristic that makes it unsuitable for many large SPAs: it requires a separate build of the application for each supported language. The user's language is typically determined by the URL (e.g., `example.com/en/`, `example.com/fr/`), and they are served a completely different set of application files.

For applications that require users to switch languages on the fly, without a full page reload, a runtime i18n library is necessary. **Transloco** is the most popular and powerful i18n library for Angular, designed for scalability and developer experience.

- **Resource:** [Transloco Official Documentation](https://jsverse.gitbook.io/transloco/)
- **Resource:** [Angular Tutorial on Localizing with Transloco](https://phrase.com/blog/posts/angular-10-tutorial-localization-transloco/)

## 1. Setting up Transloco

Transloco provides schematics to make setup quick and easy.

```bash
ng add @ngneat/transloco
```
The schematic will ask you for the languages you want to support (e.g., `en, es, fr`), and it will automatically create the necessary files:
-   `transloco.config.ts`: The main configuration file.
-   `TranslocoHttpLoader`: A service for loading translation files over HTTP.
-   `assets/i18n/`: A directory containing your JSON translation files (`en.json`, `es.json`, etc.).

It will also update your `app.config.ts` to provide the Transloco services.

## 2. Using Transloco in Templates

Transloco provides a structural directive and a pipe for easy use in templates.

### The `*transloco` Structural Directive

This is the most efficient way to handle translations in a template. It creates a single subscription for the entire template block.

**`en.json`**
```json
{
  "title": "Hello World",
  "user": {
    "name": "Welcome, {{name}}"
  }
}
```

**Component Template:**
```html
<!-- The `*transloco` directive reads the keys from the translation file -->
<ng-container *transloco="let t">
  <h1>{{ t('title') }}</h1>
  <p>{{ t('user.name', { name: userName }) }}</p>
</ng-container>
```

### The `transloco` Pipe

The pipe is useful for simple, one-off translations.

```html
<h1>{{ 'title' | transloco }}</h1>
<p>{{ 'user.name' | transloco:{ name: userName } }}</p>
```

## 3. Switching the Language at Runtime

The `TranslocoService` allows you to programmatically change the active language. This makes building a language switcher component straightforward.

```typescript
// language-switcher.component.ts
import { Component, inject } from '@angular/core';
import { TranslocoService } from '@ngneat/transloco';

@Component({ /* ... */ })
export class LanguageSwitcherComponent {
  private translocoService = inject(TranslocoService);

  availableLangs = this.translocoService.getAvailableLangs();
  activeLang = this.translocoService.getActiveLang();

  setActiveLang(lang: string) {
    this.translocoService.setActiveLang(lang);
    this.activeLang = lang;
  }
}
```

## 4. Scaling with Lazy Loading (Scopes)

For a large application, loading all translations for all languages upfront is inefficient. Transloco supports **scopes**, which allow you to split your translation files by feature module. This means you only load the translations for a feature when that feature itself is lazy-loaded.

**1. Configure Scopes:**
In your `transloco.config.ts`, you can define the available scopes.

```typescript
// transloco.config.ts
// ...
  scopes: {
    admin: 'assets/i18n/admin',
    dashboard: 'assets/i18n/dashboard'
  }
// ...
```

**2. Provide the Scope in a Lazy-Loaded Module:**
In the routing file for your lazy-loaded module, you provide the `TRANSLOCO_SCOPE`.

```typescript
// admin.routes.ts
import { provideTranslocoScope } from '@ngneat/transloco';

export const ADMIN_ROUTES: Routes = [
  {
    path: '',
    component: AdminComponent,
    providers: [
      // This tells Transloco to load the 'admin' scope when this
      // route is activated.
      provideTranslocoScope('admin')
    ]
  }
];
```

**3. Using Scoped Keys:**
In your component, you can then specify the scope when using the directive or pipe.

```html
<!-- The 'admin' scope is prepended to the key -->
<ng-container *transloco="let t; scope: 'admin'">
  <h2>{{ t('admin.title') }}</h2>
</ng-container>
```
The translation file for the admin scope would be `assets/i18n/admin/en.json`.

By combining runtime language switching with lazy-loaded translation scopes, Transloco provides a powerful and highly scalable solution for internationalizing large and complex Angular applications.