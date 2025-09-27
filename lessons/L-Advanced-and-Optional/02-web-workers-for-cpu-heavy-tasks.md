# Lesson 2: Web Workers for CPU-Heavy Tasks

The browser's main thread is responsible for everything the user sees and interacts with: rendering the UI, running JavaScript, responding to clicks, and handling animations. If you perform a long-running, CPU-intensive task on this main thread, the entire page will freeze. The user won't be able to click, scroll, or interact with anything until the task is complete.

**Web Workers** are a browser feature that solves this problem by allowing you to run a script on a separate, background thread. This offloads the heavy work from the main thread, keeping your application's UI smooth and responsive.

- **Resource:** [MDN Docs: Web Workers API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Using_web_workers)
- **Resource:** [Official Angular Guide: Using Web Workers](https://angular.io/guide/web-worker)
- **Resource:** [Angular Web Workers: What, Why, When, and How](https://medium.com/@sehban.alam/angular-web-workers-what-why-when-and-how-2025-edition-09020c531fe6)

## When to Use a Web Worker

Web Workers are ideal for tasks that are purely computational and don't need direct access to the DOM. Good candidates include:
-   Complex data processing or filtering (e.g., searching a large in-memory dataset).
-   Image or video processing.
-   Intensive mathematical calculations (e.g., cryptography, scientific simulations).
-   Parsing large files.

## 1. Generating a Web Worker

The Angular CLI makes it easy to add a web worker to your project.

```bash
ng generate web-worker my-calculator
```

This command does two things:
1.  It creates the worker script file: `src/app/my-calculator.worker.ts`.
2.  It updates your `angular.json` build configuration to correctly bundle the worker script as a separate chunk.

## 2. Implementing the Worker Script

The worker script is where you put your CPU-intensive logic. It communicates with the main application by listening for `message` events and sending results back with the `postMessage()` function.

The `/// <reference lib="webworker" />` line is important to get the correct TypeScript typings for the worker environment.

**`src/app/my-calculator.worker.ts`**
```typescript
/// <reference lib="webworker" />

// This is the entry point for the worker.
addEventListener('message', ({ data }) => {
  // `data` is the payload sent from the main app.
  console.log(`Worker received: Find primes up to ${data.maxNumber}`);

  // Perform the CPU-intensive task.
  const primes = findPrimes(data.maxNumber);

  // Send the result back to the main thread.
  postMessage({ event: 'primesCalculated', data: primes });
});

// A sample CPU-heavy function.
function findPrimes(max: number): number[] {
  const primes = [];
  for (let i = 2; i <= max; i++) {
    let isPrime = true;
    for (let j = 2; j < i; j++) {
      if (i % j === 0) {
        isPrime = false;
        break;
      }
    }
    if (isPrime) {
      primes.push(i);
    }
  }
  return primes;
}
```

## 3. Communicating from the Component

Your component is responsible for creating an instance of the worker and handling the two-way communication.

```typescript
// my-app.component.ts
import { Component, OnInit } from '@angular/core';

@Component({ /* ... */ })
export class MyAppComponent implements OnInit {
  worker: Worker | undefined;
  primes: number[] = [];
  isCalculating = false;

  ngOnInit(): void {
    // Check if Web Workers are supported by the browser.
    if (typeof Worker !== 'undefined') {
      // Create a new instance of our worker.
      this.worker = new Worker(new URL('./my-calculator.worker.ts', import.meta.url));

      // 2. Listen for messages coming FROM the worker.
      this.worker.onmessage = ({ data }) => {
        if (data.event === 'primesCalculated') {
          console.log('Main app received primes:', data.data);
          this.primes = data.data;
          this.isCalculating = false;
        }
      };
    } else {
      // Fallback for browsers that don't support Web Workers.
      console.error('Web Workers are not supported in this browser.');
    }
  }

  calculatePrimes(maxNumber: number): void {
    if (this.worker) {
      this.isCalculating = true;
      this.primes = [];
      // 1. Send a message TO the worker to start the task.
      this.worker.postMessage({ maxNumber });
    }
  }

  ngOnDestroy(): void {
    // It's good practice to terminate the worker when the component is destroyed.
    this.worker?.terminate();
  }
}
```

**The Communication Flow:**
1.  The component calls `worker.postMessage(...)`, sending data to the worker.
2.  The worker's `addEventListener('message', ...)` function is triggered. It performs the heavy calculation.
3.  The worker calls `postMessage(...)`, sending the result back to the main thread.
4.  The component's `worker.onmessage` handler is triggered, and it updates the component's state with the result.

Throughout this entire process, the main UI thread remains completely unblocked, allowing the user to continue scrolling, clicking, and interacting with the application while the heavy computation happens in the background.