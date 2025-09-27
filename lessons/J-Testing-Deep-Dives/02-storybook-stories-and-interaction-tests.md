# Lesson 2: Storybook Stories and Interaction Tests

Storybook is a powerful tool for developing, documenting, and testing UI components in isolation. It allows you to build a "component encyclopedia" for your project, where each component can be viewed and tested in its various states without needing to run the entire application.

This lesson covers how to write basic stories and how to use Storybook's `play` function to create automated **interaction tests**.

- **Resource:** [Official Storybook for Angular Guide](https://storybook.js.org/docs/angular/get-started/introduction)

## What is a "Story"?

A "story" is a single state of your component. For example, a `Button` component might have stories for its "Primary" state, "Secondary" state, "Disabled" state, and "Loading" state.

Stories are defined in a file that ends with `.stories.ts`.

### Example: Stories for a Button Component

Let's assume we have a simple `Button` component that takes a `label` and a `primary` boolean as inputs.

**`button.component.ts`**
```typescript
@Component({
  selector: 'app-button',
  template: `<button [class.primary]="primary">{{ label }}</button>`,
  // ... styles
})
export class ButtonComponent {
  @Input() label = 'Button';
  @Input() primary = false;
}
```

**`button.stories.ts`**
```typescript
import type { Meta, StoryObj } from '@storybook/angular';
import { ButtonComponent } from './button.component';

// 1. The `Meta` object describes the component.
const meta: Meta<ButtonComponent> = {
  title: 'UI/Button', // How the story will be grouped in the Storybook UI
  component: ButtonComponent,
  tags: ['autodocs'], // Enables automatic documentation generation
  argTypes: { // Describes the component's @Inputs
    primary: { control: 'boolean' },
  },
};
export default meta;

// 2. A "Story" object represents a single state.
type Story = StoryObj<ButtonComponent>;

// 3. The "Primary" story.
export const Primary: Story = {
  args: {
    primary: true,
    label: 'Primary Button',
  },
};

// 4. The "Secondary" story.
export const Secondary: Story = {
  args: {
    label: 'Secondary Button',
  },
};
```
When you run Storybook, you will see a "Button" component under the "UI" section, with two stories: "Primary" and "Secondary". You can view each one in isolation and even use Storybook's controls to change the `args` (the `@Input` values) dynamically.

## Interaction Tests with the `play` Function

Viewing components visually is great, but Storybook becomes even more powerful when you add interaction tests. A `play` function is a small snippet of code that runs *after* a story renders. It allows you to simulate user behavior (like clicks and keyboard input) and make assertions about the resulting DOM state.

The `play` function uses utilities from `@storybook/test` and `@storybook/testing-library`, which should feel very familiar if you've used Angular Testing Library.

- **Resource:** [Storybook `play` Function Documentation](https://storybook.js.org/docs/writing-stories/play-function)

### Example: Testing a Login Form

Let's imagine a simple login form component. We want to test that if a user submits the form with an empty password, an error message appears.

**`login-form.stories.ts`**
```typescript
import type { Meta, StoryObj } from '@storybook/angular';
import { within, userEvent, expect } from '@storybook/test';
import { LoginForm } from './login-form.component';

const meta: Meta<LoginForm> = {
  title: 'Forms/LoginForm',
  component: LoginForm,
};
export default meta;

type Story = StoryObj<LoginForm>;

// A story representing the initial, empty state of the form.
export const EmptyForm: Story = {};

// A story that tests the validation logic.
export const ShowsPasswordError: Story = {
  // The `play` function receives the canvas element for the story.
  play: async ({ canvasElement }) => {
    // Get a handle to the story's canvas
    const canvas = within(canvasElement);

    // 1. Find the elements a user would interact with.
    const emailInput = canvas.getByLabelText(/email/i);
    const submitButton = canvas.getByRole('button', { name: /log in/i });

    // 2. Simulate user behavior.
    // userEvent is better than fireEvent for simulating real user interactions.
    await userEvent.type(emailInput, 'test@example.com');
    await userEvent.click(submitButton);

    // 3. Assert the outcome.
    // After submitting with no password, we expect an error message to be visible.
    const passwordError = await canvas.findByText(/password is required/i);
    await expect(passwordError).toBeInTheDocument();
  },
};
```

### How it Works

1.  Storybook renders the `ShowsPasswordError` story.
2.  The `play` function executes.
3.  `within(canvasElement)` gives us access to Testing Library's query methods scoped to our component.
4.  `userEvent` simulates typing an email and clicking the submit button.
5.  `expect` (from `@storybook/test`) is used to make assertions about the DOM. We assert that the expected error message is now present.

When you run Storybook, you can watch these steps execute in the "Interactions" tab, providing a visual trace of your test. These tests can also be run in a headless browser as part of your CI pipeline using the Storybook test runner.

---

## ✅ Verifiable Outcome

You can verify your understanding of Storybook by creating stories for a component and running an interaction test.

1.  **Create Stories for a Component:**
    -   Create the simple `ButtonComponent` and its corresponding `button.stories.ts` file as described in the first example.
    -   Run the Storybook development server: `npm run storybook`.
    -   **Expected Result:** Your browser should open the Storybook UI. In the sidebar, under "UI/Button", you should see links for the "Primary" and "Secondary" stories. Clicking them should render the button in its different states. You should also be able to use the "Controls" addon at the bottom to change the `label` and `primary` properties in real-time.

2.  **Write and Run an Interaction Test:**
    -   Create the `LoginForm` component and its `login-form.stories.ts` file, including the `ShowsPasswordError` story with the `play` function.
    -   Navigate to this story in the Storybook UI.
    -   **Expected Result:** In the main panel, you will see the test running automatically. The email field will be filled, the button will be clicked, and the "password is required" error message will appear. The "Interactions" tab at the bottom will show a step-by-step log of the test, with a green checkmark next to the final `expect` assertion, confirming that your test passed.