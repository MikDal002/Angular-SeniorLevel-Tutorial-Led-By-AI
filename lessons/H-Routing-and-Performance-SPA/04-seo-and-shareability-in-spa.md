# Lesson 4: SEO and Shareability in SPAs

In a traditional multi-page application, every page has its own `index.html` file with a dedicated `<title>` and `<meta>` tags. This is great for Search Engine Optimization (SEO) and for social media platforms that scrape these tags to generate rich preview cards.

In a Single-Page Application (SPA), we only have one `index.html`. The "pages" are dynamically rendered on the client side. This means we need to programmatically update the title and meta tags as the user navigates through the application.

- **Resource:** [Angular `Title` Service Documentation](https://angular.io/api/platform-browser/Title)
- **Resource:** [Angular `Meta` Service Documentation](https://angular.io/api/platform-browser/Meta)

## The Big Caveat: Client-Side vs. Server-Side

Before we begin, it's crucial to understand a major limitation: **Many search engine crawlers and social media bots do not execute JavaScript.**

This means that even if you dynamically update your meta tags using the techniques below, the crawlers might only ever see the original, static tags from your `index.html` file.

**For robust SEO and shareability, Server-Side Rendering (SSR) with a framework like Angular Universal is often necessary.** SSR pre-renders the page on the server, so the initial HTML response sent to the browser (or crawler) already contains the correct title and meta tags for that specific route.

This lesson focuses on the client-side techniques, which are still valuable for improving the user experience (e.g., correct browser tab titles, bookmark names) and work with more advanced crawlers like Googlebot.

## Using the `Title` Service

Angular's `Title` service makes it trivial to change the document's title.

1.  **Inject the `Title` service** into your component.
2.  Call `this.title.setTitle('Your New Title')` when the component initializes.

**Example:**
```typescript
// product-details.component.ts
import { Component, OnInit, inject } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { ProductService } from './product.service'; // Assuming a service to get product data

@Component({ /* ... */ })
export class ProductDetailsComponent implements OnInit {
  private titleService = inject(Title);
  private productService = inject(ProductService);

  ngOnInit() {
    // Fetch product data
    this.productService.getProduct('123').subscribe(product => {
      // Set the title dynamically based on the data
      this.titleService.setTitle(`My Awesome Store - ${product.name}`);
    });
  }
}
```

## Using the `Meta` Service

The `Meta` service works similarly, but it allows you to add, update, or remove any `<meta>` tag in the document's `<head>`. This is essential for setting descriptions and the special tags used by social media platforms.

-   **Open Graph (Facebook, LinkedIn, etc.):** Uses `og:` prefixed properties (e.g., `og:title`, `og:description`, `og:image`).
-   **Twitter Cards:** Uses `twitter:` prefixed properties (e.g., `twitter:card`, `twitter:title`, `twitter:image`).

### Example: Setting Meta Tags for a Product Page

```typescript
// product-details.component.ts
import { Component, OnInit, inject } from '@angular/core';
import { Title, Meta } from '@angular/platform-browser';
import { ProductService } from './product.service';

@Component({ /* ... */ })
export class ProductDetailsComponent implements OnInit {
  private titleService = inject(Title);
  private metaService = inject(Meta);
  private productService = inject(ProductService);

  ngOnInit() {
    this.productService.getProduct('123').subscribe(product => {
      const title = `My Awesome Store - ${product.name}`;
      const description = product.description;
      const imageUrl = product.imageUrl;

      // 1. Set the page title
      this.titleService.setTitle(title);

      // 2. Set standard meta tags
      this.metaService.updateTag({ name: 'description', content: description });

      // 3. Set Open Graph meta tags for social sharing
      this.metaService.updateTag({ property: 'og:title', content: title });
      this.metaService.updateTag({ property: 'og:description', content: description });
      this.metaService.updateTag({ property: 'og:image', content: imageUrl });
      this.metaService.updateTag({ property: 'og:type', content: 'website' });

      // 4. Set Twitter Card meta tags
      this.metaService.updateTag({ name: 'twitter:card', content: 'summary_large_image' });
      this.metaService.updateTag({ name: 'twitter:title', content: title });
      this.metaService.updateTag({ name: 'twitter:description', content: description });
      this.metaService.updateTag({ name: 'twitter:image', content: imageUrl });
    });
  }
}
```
*Note: `updateTag` is convenient because it will add the tag if it doesn't exist or update it if it does.*

## Sitemaps

A `sitemap.xml` file is a file that lists all the important URLs on your website, helping search engines to discover and crawl them more effectively.

For a client-side SPA, creating a sitemap is typically a **build-time or server-side process**. You cannot generate it dynamically on the client. You would need a script that runs as part of your deployment pipeline to:
1.  Query your API or database for all public resources (e.g., all product IDs).
2.  Generate an XML file in the sitemap format containing the URLs for each resource (e.g., `https://www.mystore.com/products/123`).
3.  Place this `sitemap.xml` file in the root of your deployed application.

While client-side tools can manage titles and meta tags for the user and modern crawlers, a complete SEO and shareability strategy for a large SPA often requires server-side support (SSR) and build-time processes (sitemap generation).