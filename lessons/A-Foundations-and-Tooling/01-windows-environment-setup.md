# Lesson 1: Windows Environment Setup and VS Code Extensions

This lesson guides you through setting up a professional development environment on Windows for modern Angular applications. We'll install Node.js, Yarn, and the Angular CLI, then configure Visual Studio Code with essential extensions for productivity and code quality.

## 1. Install Core Dependencies

A modern web development workflow starts with the right tooling. We'll use the official installers for each tool to ensure they are correctly set up and added to your system's PATH.

### Recommended: Node Version Manager (NVM) for Windows

Different projects may require different versions of Node.js. A Node Version Manager (NVM) allows you to easily switch between Node.js versions on a per-project basis. This is a highly recommended best practice.

- **Action:** [Download and run the installer for nvm-windows](https://github.com/coreybutler/nvm-windows/releases).
- **Verification:** Open a new terminal and run `nvm --version`.
- **Usage:**
  ```bash
  # Install the latest Long-Term Support (LTS) version of Node.js
  nvm install lts

  # Set the LTS version as the one to use
  nvm use [version_number_from_previous_command]

  # Verify the node and npm versions
  node -v && npm -v
  ```
- **Resource:** [NVM for Windows GitHub Repository](https://github.com/coreybutler/nvm-windows)

### Node.js (LTS)

If you choose not to use NVM, you can install Node.js directly. Node.js is the JavaScript runtime that powers our development server, build tools, and dependency management. Always use the Long-Term Support (LTS) version for the best stability.

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

### Recommended VS Code Extensions

To significantly improve your development experience, we recommend installing several key extensions. Each of these is covered in a dedicated mini-lesson that explains its value and shows how to use it.

- **Essential for Angular:**
  - [Angular Language Service](./vscode-extensions/01-angular-language-service.md) - Provides rich IntelliSense and error-checking in templates.

- **Code Quality & Formatting:**
  - [ESLint](./vscode-extensions/02-eslint.md) - For real-time code analysis and style enforcement.
  - [Prettier - Code formatter](./vscode-extensions/03-prettier.md) - For automatic, consistent code formatting.

- **Workflow & UI Improvements:**
  - [Material Icon Theme](./vscode-extensions/04-material-icon-theme.md) - For improved visual navigation of your project files.
  - [Auto Rename Tag](./vscode-extensions/05-auto-rename-tag.md) - A simple time-saver for editing HTML.

## 3. Further Reading

- **Blog Post:** [Getting Started with Node.js, Angular, and Visual Studio Code](https://devblogs.microsoft.com/premier-developer/getting-started-with-node-js-angular-and-visual-studio-code/) - A helpful guide from Microsoft.
- **Article:** [Top VS Code Extensions for Angular Developers](https://dev.to/manthanank/top-vs-code-extensions-for-angular-developers-4374) - A good overview of useful extensions.

---

## ✅ Verifiable Outcome

The best way to verify that your entire environment is set up correctly is to create and run a new Angular application.

1.  **Create the Project:**
    -   Open a new terminal or PowerShell window.
    -   Run the command: `ng new test-app`
    -   The Angular CLI will ask you a few questions. Accept the defaults for now. This will create a new directory named `test-app` with a fresh Angular project.

2.  **Run the Application:**
    -   Navigate into the new directory: `cd test-app`
    -   Run the local development server: `ng serve`
    -   Open your web browser and navigate to `http://localhost:4200`.

3.  **Expected Result:**
    -   You should see the default Angular welcome page loading in your browser without any errors in the terminal. This confirms that Node.js, npm, and the Angular CLI are all installed and working together correctly.

4.  **Check VS Code Integration:**
    -   Open the `test-app` folder in VS Code.
    -   Open `src/app/app.component.html`.
    -   **Expected Result:** You should not see any errors about unrecognized tags. The "Angular Language Service" extension should provide syntax highlighting and basic analysis.