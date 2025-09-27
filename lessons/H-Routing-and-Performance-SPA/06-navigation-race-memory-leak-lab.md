# Lesson 6: Lab - Navigation Race/Memory Leak

This lab demonstrates how to diagnose and fix two of the most common and subtle bugs in a Single-Page Application: navigation race conditions and subscription-based memory leaks. Both issues stem from improperly handling observable streams during route navigation.

## The Scenario

Imagine we have a `UserDetailsComponent` that displays details for a user based on an `id` from the route parameters (`/users/:id`). The `UserService` has a `getUserById` method that simulates a slow network request.

**The `UserService`:**
```typescript
@Injectable({ providedIn: 'root' })
export class UserService {
  getUserById(id: string): Observable<User> {
    // Simulate a slow network request with a random delay
    const delay = Math.random() * 1500;
    const user: User = { id, name: `User ${id}` };
    return of(user).pipe(delay(delay));
  }
}
```

## The "Broken" Component

Here is a version of the `UserDetailsComponent` with both a race condition and a memory leak.

```typescript
// user-details.component.ts (BROKEN VERSION)
@Component({ /* ... */ })
export class UserDetailsComponent implements OnInit, OnDestroy {
  user: User | null = null;

  constructor(
    private route: ActivatedRoute,
    private userService: UserService
  ) {
    console.log('UserDetailsComponent created');
  }

  ngOnInit() {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        // This subscription is never unsubscribed from, causing a memory leak.
        this.userService.getUserById(id).subscribe(user => {
          console.log('Received user data:', user);
          this.user = user;
        });
      }
    });
  }

  ngOnDestroy() {
    console.log('UserDetailsComponent destroyed');
  }
}
```

---

## ✅ Verifiable Outcome

You can verify the broken behavior and the subsequent fix by running the application and observing the console.

### 1. Observe the Memory Leak

-   Implement the **"Broken"** version of the `UserDetailsComponent`.
-   Navigate to `/users/1`.
-   Navigate to another page (e.g., home).
-   **Expected Result:** In the browser console, you will see "UserDetailsComponent created" and then "UserDetailsComponent destroyed". However, after the component is destroyed, you will still see a "Received user data..." log message appear after a short delay. This is the memory leak in action—the subscription is still alive and running.

### 2. Observe the Race Condition
-   With the **"Broken"** version, add links to navigate between `/users/1` and `/users/2`.
-   Click the link for `/users/1`, and then immediately (within a second) click the link for `/users/2`.
-   **Expected Result:** Watch the UI. It's very likely that the page will first show "User 2", and then a moment later it will incorrectly flip back to showing "User 1", even though the URL is still `/users/2`. This demonstrates the race condition.

### 3. Verify the Fix
-   Implement the **"Fixed"** version of the `UserDetailsComponent` using the declarative `product$` stream.
-   Repeat the memory leak test. When you navigate away from the user details page, you should **not** see any further "Received user data" logs.
-   Repeat the race condition test. When you navigate quickly from `/users/1` to `/users/2`, the UI should correctly display "User 2" and stay that way, because the `switchMap` operator canceled the request for the first user.

## The "Fixed" Component

The solution to both problems is to use a single, declarative observable stream that is properly tied to the component's lifecycle and uses the correct flattening operator.

```typescript
// user-details.component.ts (FIXED VERSION)
import { Component, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { UserService } from './user.service';
import { switchMap, map, filter } from 'rxjs/operators';
import { toSignal } from '@angular/core/rxjs-interop';

@Component({
  selector: 'app-user-details',
  template: `
    <div *ngIf="user(); else loading">
      <h2>{{ user()?.name }}</h2>
      <p>ID: {{ user()?.id }}</p>
    </div>
    <ng-template #loading>
      <p>Loading user...</p>
    </ng-template>
  `
})
export class UserDetailsComponent {
  private route = inject(ActivatedRoute);
  private userService = inject(UserService);

  private user$ = this.route.paramMap.pipe(
    map(params => params.get('id')),
    filter(id => !!id),
    // Solution for Race Condition: switchMap cancels the previous,
    // in-flight request for getUserById when a new id arrives.
    switchMap(id => this.userService.getUserById(id!))
  );

  // Solution for Memory Leak: toSignal handles the subscription
  // and automatically unsubscribes when the component is destroyed.
  user = toSignal(this.user$);
}
```

### Why This Fixes the Problems

1.  **`switchMap` Fixes the Race Condition:** `switchMap` is the key. When the user navigates from `/users/1` to `/users/2`, the `paramMap` observable emits a new `id`. `switchMap` immediately unsubscribes from the pending `getUserById('1')` request and "switches" to a new `getUserById('2')` request. The first request is canceled in-flight, so its result can never incorrectly overwrite the new data.

2.  **`toSignal` (or `takeUntilDestroyed`) Fixes the Memory Leak:** By using `toSignal` (or a manual subscription with the `takeUntilDestroyed()` operator), the entire observable pipeline is automatically tied to the component's lifecycle. When `UserDetailsComponent` is destroyed, the subscription to `paramMap` is terminated, preventing any memory leaks.

This lab demonstrates that by using declarative RxJS patterns (`switchMap`) and proper lifecycle management (`toSignal`/`takeUntilDestroyed`), you can create routing and data-fetching logic that is robust, efficient, and free from common race conditions and memory leaks.