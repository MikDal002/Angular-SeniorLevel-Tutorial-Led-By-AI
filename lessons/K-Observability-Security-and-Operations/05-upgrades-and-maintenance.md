# Lesson 5: Upgrades and Maintenance

The web ecosystem moves fast, and Angular is no exception. The Angular team releases a new major version every six months, with minor versions and patches in between. Keeping your application up-to-date is crucial for security, performance, and access to the latest features.

Fortunately, the Angular team places a strong emphasis on making this process as smooth as possible, primarily through the Angular CLI and the official Angular Update Guide.

## The Angular Update Guide: Your First Stop

Before starting any upgrade, your first and most important resource is the official **Angular Update Guide**.

- **Resource:** [Angular Update Guide](https://update.angular.io/)
- **Resource:** [Angular Release and Versioning Guide](https://angular.dev/reference/releases)

This interactive tool provides a customized, step-by-step checklist for your specific upgrade path. You select your current version and your target version, and it generates a detailed list of commands to run and manual changes to make. **Always consult this guide before a major version upgrade.**

![Angular Update Guide Screenshot](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*e4v6w8Y7Z5j6k9Q3jJ3g9g.png)
*(Image credit: Aleksandra Setsumei)*

## The `ng update` Command

The core of the Angular upgrade process is the `ng update` command. This command is much more powerful than a simple `npm install`. It not only updates your package versions in `package.json` but also runs **schematics** (automated code modification scripts) that can handle many common breaking changes for you, updating your code to be compatible with the new version.

- **Resource:** [`ng update` CLI Documentation](https://angular.dev/cli/update)

### A Safe and Repeatable Upgrade Process

Here is a safe, step-by-step process to follow when performing an upgrade.

**Step 1: Ensure Your Code is Clean**
Before starting, make sure your project has no uncommitted changes in git. This is a safety net; if something goes wrong during the update, you can easily revert everything. The `ng update` command will often refuse to run if you have a "dirty" working directory.

**Step 2: Update One Major Version at a Time**
Do not try to jump from version 14 to version 17 in one go. The recommended path is to upgrade incrementally, one major version at a time (14 -> 15, then 15 -> 16, etc.). This makes troubleshooting much easier.

**Step 3: Run the Basic Update Command**
The command to update the core Angular packages to the next major version is:

```bash
# Example: Updating from v16 to v17
ng update @angular/core@17 @angular/cli@17
```
The CLI will analyze your `package.json`, update the versions, install the new packages, and run any available migration schematics. Pay close attention to the output in the console, as it will often provide valuable information about what was changed.

**Step 4: Update Third-Party Libraries**
After updating the core framework, you need to update your other Angular-related libraries (e.g., Angular Material, NgRx, ng-bootstrap). You can often update these with `ng update` as well.

```bash
ng update @angular/material
ng update @ngrx/store
```
Check the documentation for each of your third-party libraries for their specific upgrade instructions and compatibility with your target Angular version.

**Step 5: Test Thoroughly**
After the update commands are complete, run your application (`ng serve`) and execute your entire test suite (`ng test`). Click through the application manually to ensure that everything looks and behaves as expected. Fix any issues that arise.

**Step 6: Commit and Repeat**
Once you are confident that the application is stable on the new version, commit your changes. Now you are ready to start the process again for the next major version.

## Why Stay Current?

While upgrading can seem like a chore, the benefits are significant:
-   **Performance:** Each new version of Angular typically brings performance improvements.
-   **Features:** Access to new APIs and features (like Signals, `@defer`, etc.) that can make your code better and easier to write.
-   **Security:** Regular updates ensure you have the latest security patches.
-   **Easier Upgrades:** The longer you wait, the larger the gap between versions becomes, and the more difficult the upgrade process will be. Small, regular updates are much easier than a massive, multi-version jump.

By following the official Update Guide and using the power of `ng update`, you can keep your Angular applications modern, performant, and secure with minimal friction.