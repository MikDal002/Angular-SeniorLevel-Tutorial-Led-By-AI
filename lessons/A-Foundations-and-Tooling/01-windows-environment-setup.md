# Lesson 1: Windows Environment Setup and VS Code Extensions

This lesson guides you through setting up a professional development environment on Windows for modern Angular applications. We'll install Node.js, Yarn, and the Angular CLI, then configure Visual Studio Code with essential extensions for productivity and code quality.

## 1. Install Core Dependencies

A modern web development workflow starts with the right tooling. We'll use the official installers for each tool to ensure they are correctly set up and added to your system's PATH.

### Node.js (LTS)

Node.js is the JavaScript runtime that powers our development server, build tools, and dependency management. Always use the Long-Term Support (LTS) version for the best stability.

- **Action:** [Download and install Node.js LTS](https://nodejs.org/en/download/) for Windows.
- **Verification:** Open a new PowerShell or Command Prompt window and run `node -v` and `npm -v`. You should see the installed versions.

### Yarn

Yarn is a fast, reliable, and secure dependency manager. While `npm` is bundled with Node.js, Yarn offers improvements in performance and consistency.

- **Action:** [Install Yarn](https://classic.yarnpkg.com/en/docs/install#windows-stable) using the recommended method for your system. The simplest is often via `npm`:
  ```bash
  npm install --global yarn
  ```
- **Verification:** In a new terminal, run `yarn --version`.

### Angular CLI

The Angular CLI is the official command-line interface for Angular. It helps you create, build, test, and deploy Angular applications.

- **Action:** Install the Angular CLI globally using `npm`:
  ```bash
  npm install -g @angular/cli
  ```
- **Verification:** In a new terminal, run `ng --version`. You should see the Angular CLI banner and version details.

## 2. Configure Visual Studio Code

Visual Studio Code is our recommended code editor. Its rich ecosystem of extensions makes it a powerful tool for Angular development.

- **Action:** [Download and install VS Code](https://code.visualstudio.com/download) if you haven't already.

### Essential VS Code Extensions

These extensions provide features like code completion, linting, and navigation, which are critical for a high-quality development experience.

- **[Angular Language Service](https://marketplace.visualstudio.com/items?itemName=Angular.ng-template)**: Provides rich editing features for Angular templates, including completions, error checking, and navigation. This is a must-have for any Angular developer.
- **[ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)**: Integrates ESLint into VS Code to highlight and fix problems in your TypeScript code, helping you enforce consistent coding standards.
- **[Prettier - Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)**: An opinionated code formatter that ensures a consistent code style across your entire project.
- **[Material Icon Theme](https://marketplace.visualstudio.com/items?itemName=PKief.material-icon-theme)**: Provides beautiful and informative icons for files and folders, making it easier to navigate your project structure.
- **[Path Intellisense](https://marketplace.visualstudio.com/items?itemName=christian-kohler.path-intellisense)**: Autocompletes filenames, which is incredibly helpful for managing imports and asset paths.

### Recommended Workflow Extensions

These extensions streamline common development tasks.

- **[Auto Import](https://marketplace.visualstudio.com/items?itemName=steoates.autoimport)**: Automatically finds, parses, and provides code actions and code completion for all available imports.
- **[Auto Rename Tag](https://marketplace.visualstudio.com/items?itemName=formulahendry.auto-rename-tag)**: Automatically renames paired HTML/XML tags, saving you time and preventing errors.

## 3. Further Reading

- **Blog Post:** [Getting Started with Node.js, Angular, and Visual Studio Code](https://devblogs.microsoft.com/premier-developer/getting-started-with-node-js-angular-and-visual-studio-code/) - A helpful guide from Microsoft.
- **Article:** [Top VS Code Extensions for Angular Developers](https://dev.to/manthanank/top-vs-code-extensions-for-angular-developers-4374) - A good overview of useful extensions.

With these tools and extensions in place, your environment is now optimized for building high-quality Angular applications efficiently.