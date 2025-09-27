# Lesson 3: Quality Gates and Hooks

This lesson covers setting up automated quality gates for your project. We'll use a combination of tools to enforce commit message conventions, run linters before committing, and automate the entire release process. This setup ensures that all code entering the repository is clean and that releases are consistent and predictable.

## 1. Husky: Git Hooks Made Easy

Husky is a tool that allows us to easily manage Git hooks. We'll use it to trigger scripts at specific points in the Git lifecycle, such as before a commit or a push.

- **Action:** Install Husky.
  ```bash
  npm install husky --save-dev
  ```
- **Action:** Enable Git hooks.
  ```bash
  npx husky install
  ```
- **Action:** To automatically have Git hooks enabled after install, run the following command:
  ```bash
  npm set-script prepare "husky install"
  ```
- **Resource:** [Husky Documentation](https://typicode.github.io/husky/)

## 2. lint-staged: Run Linters on Staged Files

Running your entire test suite on every commit can be slow. `lint-staged` allows you to run scripts on just the files that are staged for a commit, which is much faster.

- **Action:** Install `lint-staged`.
  ```bash
  npm install --save-dev lint-staged
  ```
- **Action:** Configure `lint-staged` in your `package.json`:
  ```json
  "lint-staged": {
    "*.{ts,html}": [
      "eslint --fix",
      "prettier --write"
    ]
  }
  ```
- **Action:** Create a `pre-commit` hook that runs `lint-staged`.
  ```bash
  npx husky add .husky/pre-commit "npx lint-staged"
  ```
- **Resource:** [lint-staged Documentation](https://github.com/okonet/lint-staged)

## 3. commitlint: Enforce Commit Message Conventions

Consistent commit messages are key to a maintainable project history and are essential for automated tools like `semantic-release`. `commitlint` helps enforce a commit message format.

- **Action:** Install `commitlint` and the conventional changelog configuration.
  ```bash
  npm install --save-dev @commitlint/cli @commitlint/config-conventional
  ```
- **Action:** Create a `commitlint.config.js` file in your project root:
  ```javascript
  module.exports = {
    extends: ['@commitlint/config-conventional'],
  };
  ```
- **Action:** Add a `commit-msg` hook to run `commitlint`.
  ```bash
  npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'
  ```
- **Resource:** [commitlint Documentation](https://commitlint.js.org/)

## 4. semantic-release: Fully Automated Versioning and Package Publishing

`semantic-release` automates the entire release process. It analyzes your commit messages to determine the next version number, generates a changelog, and publishes the package.

- **Action:** Install `semantic-release` and its plugins.
  ```bash
  npm install --save-dev semantic-release @semantic-release/changelog @semantic-release/git
  ```
- **Action:** Configure `semantic-release` in a `.releaserc.json` file in your project root:
  ```json
  {
    "branches": ["main"],
    "plugins": [
      "@semantic-release/commit-analyzer",
      "@semantic-release/release-notes-generator",
      "@semantic-release/changelog",
      ["@semantic-release/npm", { "npmPublish": false }],
      ["@semantic-release/git", {
        "assets": ["package.json", "CHANGELOG.md"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }]
    ]
  }
  ```
  *Note: We've set `npmPublish` to `false` as we are building an application, not a library to be published to npm.*
- **Action:** Add a release script to your `package.json`:
  ```json
  "scripts": {
    "release": "semantic-release"
  }
  ```
- **Resource:** [semantic-release Documentation](https://semantic-release.gitbook.io/semantic-release/)
- **Further Reading:** [Embracing Automated Versioning with Semantic Release](https://igventurelli.io/embracing-automated-versioning-with-semantic-release/)

---

## ✅ Verifiable Outcome

After completing this lesson, you can verify that the quality gates are working correctly by performing the following tests in your terminal:

1.  **Test the `pre-commit` hook:**
    -   Open any `.ts` file and intentionally introduce a syntax or linting error (e.g., `const x: string = 123;`).
    -   Stage the file: `git add .`
    -   Try to commit it: `git commit -m "test: add broken file"`
    -   **Expected Result:** The commit should **fail**. The `lint-staged` hook will run ESLint, which will find the error and prevent the commit.

2.  **Test the `commit-msg` hook:**
    -   Fix the linting error you introduced in the previous step.
    -   Stage the file again: `git add .`
    -   Try to commit with a non-conventional commit message: `git commit -m "updated stuff"`
    -   **Expected Result:** The commit should **fail**. The `commitlint` hook will validate the message and reject it because it doesn't follow the format (e.g., `feat:`, `fix:`, `chore:`, etc.).

3.  **Test a successful commit:**
    -   With the linting error fixed, commit with a valid message: `git commit -m "chore: setup git hooks"`
    -   **Expected Result:** The commit should **succeed**.