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

### Lab Task 1: Identify the Memory Leak

1.  Navigate to `/users/1`. You will see "UserDetailsComponent created" and "Received user data: User 1" in the console.
2.  Navigate to another page (e.g., home). You will see "UserDetailsComponent destroyed".
3.  The `paramMap` subscription is a long-lived observable. Even though the component is destroyed, the subscription inside `ngOnInit` remains active in memory. This is a classic memory leak. With enough navigations, this would slow down and eventually crash the application.

### Lab Task 2: Identify the Race Condition

1.  Add links to your app to navigate between `/users/1`, `/users/2`, and `/users/3`.
2.  Click quickly between the links (e.g., click "User 1", then immediately click "User 2" before the first request finishes).
3.  Observe the console logs. Because of the random delay, you might see the following sequence:
    -   (Navigating to User 1...)
    -   (Navigating to User 2...)
    -   `Received user data: {id: "2", name: "User 2"}` -> UI updates to show User 2.
    -   `Received user data: {id: "1", name: "User 1"}` -> **RACE CONDITION!** The slower request for User 1 finishes *last* and incorrectly overwrites the UI, leaving you on the `/users/2` URL but seeing data for User 1.

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