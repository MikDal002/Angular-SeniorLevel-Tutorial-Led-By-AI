# Lesson 7: Lab - 412 Precondition Failed (ETag/If-Match)

This lesson is a practical lab on handling optimistic concurrency conflicts. This is a common problem in multi-user applications where two users might try to edit the same resource at the same time. The goal is to prevent a user from accidentally overwriting another user's changes. This is often called preventing a "mid-air collision."

We can solve this using standard HTTP headers: `ETag` and `If-Match`.

- **Resource:** [MDN: 412 Precondition Failed](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/412)
- **Resource:** [MDN: If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match)

## The Scenario

1.  **User A** loads an "Edit Product" page. The server sends the product data and also an `ETag` header (e.g., `ETag: "v1-abc"`). The `ETag` is a unique identifier representing the version of the resource User A just loaded. The client stores this ETag.
2.  **User B** loads the same "Edit Product" page. They also receive the `ETag: "v1-abc"`.
3.  **User B** saves their changes first. The server updates the product and generates a new ETag for the new version (e.g., `ETag: "v2-def"`), which it sends back to User B.
4.  **User A** now tries to save their changes. The client sends the product data and also includes the `If-Match: "v1-abc"` header, indicating that the server should only perform the update if the resource's current version on the server is still `"v1-abc"`.
5.  The server checks. The current version is `"v2-def"`, which does not match the `If-Match` header from User A.
6.  The server rejects the request with a **`412 Precondition Failed`** status code, preventing User A from overwriting User B's changes.
7.  The client can now catch this specific error and show the user a helpful dialog (e.g., "This product has been modified by someone else. Would you like to reload the latest version?").

## Lab Part 1: Storing the ETag

First, we need a way to get the `ETag` from a `GET` response and store it. We can create a simple service for this.

```typescript
// etag.service.ts
import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class EtagService {
  private etagCache = new Map<string, string>();

  // Called by an interceptor when a GET response is received
  setEtag(url: string, etag: string): void {
    this.etagCache.set(url, etag);
  }

  // Called by an interceptor before a PUT/PATCH request is sent
  getEtag(url: string): string | undefined {
    return this.etagCache.get(url);
  }
}
```

## Lab Part 2: The Concurrency Interceptor

Next, we'll create an `HttpInterceptor` that does two things:
1.  On a successful `GET` response, it looks for an `ETag` header and stores it in our `EtagService`.
2.  Before a `PUT` or `PATCH` request is sent, it looks for a stored `ETag` for that URL and, if found, adds the `If-Match` header to the request.

```typescript
// concurrency.interceptor.ts
import { Injectable, inject } from '@angular/core';
import {
  HttpEvent, HttpInterceptor, HttpHandler, HttpRequest, HttpResponse
} from '@angular/common/http';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { EtagService } from './etag.service';

@Injectable()
export class ConcurrencyInterceptor implements HttpInterceptor {
  private etagService = inject(EtagService);

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // For write requests (PUT, PATCH), add the If-Match header
    if (req.method === 'PUT' || req.method === 'PATCH') {
      const etag = this.etagService.getEtag(req.url);
      if (etag) {
        req = req.clone({
          setHeaders: { 'If-Match': etag }
        });
      }
    }

    return next.handle(req).pipe(
      tap(event => {
        // For GET requests, store the ETag from the response
        if (req.method === 'GET' && event instanceof HttpResponse) {
          const etag = event.headers.get('ETag');
          if (etag) {
            this.etagService.setEtag(req.url, etag);
          }
        }
      })
    );
  }
}
```
Remember to provide this interceptor in your `app.config.ts`.

## Lab Part 3: Handling the 412 Error in a Component

Finally, in your component that saves the data, you need to specifically handle the `412` error.

```typescript
// product-edit.component.ts
import { Component, OnInit, inject } from '@angular/core';
import { ProductService } from './product.service';
import { catchError, of } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';

@Component({ /* ... */ })
export class ProductEditComponent implements OnInit {
  private productService = inject(ProductService);
  product: Product;

  ngOnInit() {
    // Load the product data. The interceptor will automatically store the ETag.
    this.productService.getProduct('123').subscribe(p => this.product = p);
  }

  onSave() {
    this.productService.updateProduct(this.product).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 412) {
          // Handle the mid-air collision
          if (confirm('This product was modified by someone else. Reload to see the latest changes?')) {
            // Reload the data
            this.ngOnInit();
          }
        } else {
          // Handle other errors
          console.error('An unexpected error occurred.', error);
        }
        return of(null); // End the stream gracefully
      })
    ).subscribe(response => {
      if (response) {
        console.log('Save successful!');
      }
    });
  }
}
```

This lab demonstrates a complete, robust pattern for optimistic concurrency control. It prevents data loss, provides a clear path for user resolution, and relies on standard, well-understood HTTP mechanisms.