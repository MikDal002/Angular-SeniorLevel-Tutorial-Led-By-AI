# Lesson 5: Role/Claim-Based UI (Structural Directives/Pipes)

Route guards are excellent for protecting entire pages, but often you need more granular control within a component's template. You might need to show an "Edit" button only to users with an `editor` role, or hide an entire admin section of a form from non-admin users.

Hardcoding this logic with `*ngIf` statements in your components can lead to duplicated code and tightly couples your presentation logic to your authentication model. A much cleaner solution is to create reusable **structural directives** and **pipes** to handle this declarative permission checking.

- **Resource:** [Implementing Role-Based Access Control (RBAC) in Angular Applications](https://www.c-sharpcorner.com/article/implementing-role-based-access-control-rbac-in-angular-applications/)

## The Structural Directive Approach: `*ifHasRole`

A custom structural directive is the most powerful and flexible way to conditionally show or hide elements. It works just like `*ngIf`, but with our custom role-based logic.

### 1. Creating the Directive

A structural directive works by injecting `TemplateRef` (a reference to the content inside the `*` syntax) and `ViewContainerRef` (a reference to where the content should be rendered). We then programmatically create or clear the view based on our logic.

```typescript
// if-has-role.directive.ts
import { Directive, Input, TemplateRef, ViewContainerRef, inject } from '@angular/core';
import { AuthService } from './auth.service'; // Your auth service
import { takeUntil, distinctUntilChanged } from 'rxjs/operators';
import { Subject } from 'rxjs';

@Directive({
  selector: '[ifHasRole]',
  standalone: true,
})
export class IfHasRoleDirective {
  private authService = inject(AuthService);
  private templateRef = inject(TemplateRef<any>);
  private viewContainer = inject(ViewContainerRef);

  private requiredRoles: string[] = [];
  private hasView = false;
  private destroy$ = new Subject<void>();

  @Input()
  set ifHasRole(roles: string | string[]) {
    this.requiredRoles = Array.isArray(roles) ? roles : [roles];
    this.updateView();
  }

  constructor() {
    // Subscribe to user changes to dynamically update the view
    this.authService.currentUser$.pipe(
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(() => this.updateView());
  }

  private updateView(): void {
    const userHasRequiredRole = this.authService.hasRoles(this.requiredRoles);

    if (userHasRequiredRole && !this.hasView) {
      this.viewContainer.createEmbeddedView(this.templateRef);
      this.hasView = true;
    } else if (!userHasRequiredRole && this.hasView) {
      this.viewContainer.clear();
      this.hasView = false;
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
```
*(This assumes your `AuthService` has a method `hasRoles(roles: string[]): boolean` that checks the current user's claims).*

### 2. Using the Directive

Now you can use this directive in any template to declaratively hide or show content.

```html
<!-- Import the directive into your component -->
@Component({
  ...
  imports: [IfHasRoleDirective],
})

<!-- Use it in the template -->
<div>
  <h2>User Dashboard</h2>
  <p>Some content visible to everyone.</p>

  <!-- This button will only be rendered if the user has the 'admin' role -->
  <button *ifHasRole="'admin'">Manage Users</button>

  <!-- This section is only visible to editors or admins -->
  <div *ifHasRole="['editor', 'admin']">
    <h3>Content Management</h3>
    <p>Tools for editing articles...</p>
  </div>
</div>
```

## The Pipe Approach: `hasRolePipe`

A pipe is a simpler solution that is useful when you want to control an existing directive, like `[disabled]`, rather than completely removing an element from the DOM.

### 1. Creating the Pipe

A pipe is a simple class with a `transform` method. We can inject our `AuthService` and check the user's roles.

```typescript
// has-role.pipe.ts
import { Pipe, PipeTransform, inject } from '@angular/core';
import { AuthService } from './auth.service';

@Pipe({
  name: 'hasRole',
  standalone: true,
})
export class HasRolePipe implements PipeTransform {
  private authService = inject(AuthService);

  transform(roles: string | string[]): boolean {
    return this.authService.hasRoles(Array.isArray(roles) ? roles : [roles]);
  }
}
```

### 2. Using the Pipe

Pipes are great for controlling properties. For example, we can disable a button if the user *doesn't* have the required role.

```html
<!-- Import the pipe into your component -->
@Component({
  ...
  imports: [HasRolePipe],
})

<!-- Use it in the template -->
<!-- The button is visible to everyone, but only enabled for admins -->
<button [disabled]="!('admin' | hasRole)">Promote to Admin</button>
```

## Directive vs. Pipe: When to Use Which?

| Method                | Pros                                                                        | Cons                                                     | Best For                                                                  |
| --------------------- | --------------------------------------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------- |
| **Structural Directive** | Completely removes the element from the DOM, which is more secure.        | More complex to write.                                   | Hiding sections, buttons, or navigation items that a user should not see. |
| **Pipe**              | Very simple to write. Can be easily composed with other logic (e.g., `!`). | Only controls a property; the element is still in the DOM. | Disabling form fields or buttons that are visible but not interactive.    |

By creating these reusable, declarative tools, you can keep your component templates clean and free of complex authorization logic, leading to a more secure and maintainable application.