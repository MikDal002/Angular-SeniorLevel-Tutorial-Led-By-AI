# Lesson 5: File Upload/Download with Progress and Cancel

Handling file transfers is a common requirement for web applications. Angular's `HttpClient` provides all the necessary tools to build a robust and user-friendly experience for both uploading and downloading files, including progress tracking and cancellation.

## 1. File Upload

The standard way to upload a file is to send it as `multipart/form-data`. The `FormData` API makes this easy to construct.

### The Component (Template)
First, we need a simple file input in our component's template.

```html
<input type="file" (change)="onFileSelected($event)" />
<button (click)="onUpload()" [disabled]="!selectedFile">Upload</button>

<div *ngIf="uploadProgress !== null">
  <p>Progress: {{ uploadProgress }}%</p>
</div>

<button (click)="onCancel()" *ngIf="uploadSub">Cancel</button>
```

### The Component (Logic)
The component logic will handle selecting the file, initiating the upload, tracking progress, and canceling the request.

```typescript
// file-upload.component.ts
import { Component, inject } from '@angular/core';
import { HttpClient, HttpEventType, HttpRequest } from '@angular/common/http';
import { Subscription, of } from 'rxjs';
import { catchError, finalize, tap } from 'rxjs/operators';

@Component({ /* ... */ })
export class FileUploadComponent {
  private http = inject(HttpClient);
  selectedFile: File | null = null;
  uploadProgress: number | null = null;
  uploadSub: Subscription | null = null;

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.selectedFile = input.files[0];
    }
  }

  onUpload(): void {
    if (!this.selectedFile) {
      return;
    }

    const formData = new FormData();
    formData.append('file', this.selectedFile, this.selectedFile.name);

    // Create a request object with progress tracking
    const req = new HttpRequest('POST', '/api/upload', formData, {
      reportProgress: true,
      observe: 'events'
    });

    this.uploadProgress = 0;

    this.uploadSub = this.http.request(req).pipe(
      tap(event => {
        if (event.type === HttpEventType.UploadProgress) {
          this.uploadProgress = Math.round(100 * event.loaded / (event.total || 1));
        } else if (event.type === HttpEventType.Response) {
          console.log('File uploaded successfully!', event.body);
        }
      }),
      catchError(err => {
        console.error('Upload failed:', err);
        this.uploadProgress = null;
        return of(null); // Handle error gracefully
      }),
      finalize(() => {
        this.uploadSub = null; // Clear subscription on complete/error
      })
    ).subscribe();
  }

  onCancel(): void {
    if (this.uploadSub) {
      this.uploadSub.unsubscribe();
      this.uploadProgress = null;
      this.uploadSub = null;
    }
  }
}
```
- **`reportProgress: true`**: This is the key option that tells `HttpClient` to emit progress events.
- **`observe: 'events'`**: This tells `HttpClient` to return an `Observable<HttpEvent<any>>` instead of just the response body, so we can listen for `HttpEventType.UploadProgress`.
- **Cancellation:** We store the `Subscription` object from the `.subscribe()` call. Calling `.unsubscribe()` on it will cancel the in-flight HTTP request.

- **Resource:** [Angular File Upload (With Cancel Button) by Daniel Kreider](https://danielk.tech/home/angular-file-upload-with-cancel-button)

## 2. File Download

Downloading a file from an API typically involves requesting the data as a `Blob` and then creating a temporary link to trigger the browser's download functionality.

### The Download Service
It's good practice to encapsulate the download logic in a service.

```typescript
// download.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class DownloadService {
  private http = inject(HttpClient);

  download(url: string): Observable<Blob> {
    return this.http.get(url, {
      responseType: 'blob' // Critical: request the data as a raw Blob
    });
  }
}
```

### The Component
The component calls the service and, upon receiving the `Blob`, creates an `<a>` tag in memory to trigger the download.

```typescript
// file-download.component.ts
import { Component, inject } from '@angular/core';
import { DownloadService } from './download.service';

@Component({ /* ... */ })
export class FileDownloadComponent {
  private downloadService = inject(DownloadService);

  onDownload(fileUrl: string, fileName: string): void {
    this.downloadService.download(fileUrl).subscribe(blob => {
      // Create a blob URL
      const url = window.URL.createObjectURL(blob);

      // Create a link element
      const a = document.createElement('a');
      a.href = url;
      a.download = fileName; // The name for the downloaded file

      // Programmatically click the link to trigger the download
      document.body.appendChild(a);
      a.click();

      // Clean up by removing the link and revoking the blob URL
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);
    });
  }
}
```
This approach gives you full control over the download process, allowing you to show loading indicators and handle errors, while still leveraging the browser's native download capabilities.

- **Resource:** [Angular File Download with Progress](https://dev.to/angular/angular-file-download-with-progress-985)
- **Resource:** [Official Angular Docs on non-JSON data](https://angular.io/guide/http-making-requests#fetching-other-types-of-data)

---

## ✅ Verifiable Outcome

You can verify these patterns by setting up a component and mocking the backend requests.

1.  **Test File Upload:**
    -   Implement the `FileUploadComponent`. You will need a mock backend or a simple Express server that can accept a file upload to test against.
    -   Select a file using the input.
    -   Click the "Upload" button.
    -   **Expected Result:** You should see the progress bar appear and animate from 0% to 100%. The "Cancel" button should be visible during the upload.

2.  **Test Upload Cancellation:**
    -   To test cancellation, you'll need to simulate a slow upload on your mock backend.
    -   Select a file and click "Upload".
    -   While the progress bar is visible (before it reaches 100%), click the "Cancel" button.
    -   **Expected Result:** The progress bar should disappear. In your browser's DevTools "Network" tab, you should see that the pending `POST` request is immediately marked as **`(canceled)`**.

3.  **Test File Download:**
    -   Implement the `DownloadService` and `FileDownloadComponent`.
    -   Create a button in the component that calls the `onDownload` method with a URL to a sample file (e.g., a public image URL) and a desired filename.
    -   Run the application and click the download button.
    -   **Expected Result:** Your browser's native download prompt should appear, asking you to save the file with the filename you specified in the component.