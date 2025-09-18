# Syllabus

## Module A — Foundations and Tooling
- [ ] Windows environment setup and VS Code extensions: You’ll have Node LTS, Yarn, Angular CLI, and VS Code configured with strict TypeScript and recommended extensions.
- [ ] SPA project scaffold with strict TS, ESLint/Prettier, Jest, ATL, Storybook, Playwright: You’ll create a modern Angular SPA with all core tooling wired.
- [ ] Quality gates and hooks (commitlint, husky, lint-staged, semantic-release): You’ll enforce local commit and code-quality gates and set up automated versioning.
- [ ] GitHub Actions CI baseline: You’ll run lint, type-check, unit, component, and E2E suites with caching and artifacts in GitHub Actions.
- [ ] Angular Material and theme setup: You’ll install Material, configure theming/typography/density, and verify a consistent UI baseline.
- [ ] Change detection pitfall clinic (OnPush + mutation bug): You’ll reproduce a stale-view bug and fix it with immutable updates, signals, and trackBy.

## Module B — Architecture and Feature Slicing
- [ ] Feature-sliced structure: You’ll organize core, shared, and feature layers with clear boundaries and responsibilities.
- [ ] Core services and cross-cutting concerns: You’ll centralize configuration, interceptors, error handling, logging, and app-level utilities.
- [ ] Shared UI patterns: You’ll build reusable, pure UI components with strict inputs/outputs and no domain leakage.
- [ ] Domain and adapters (SOLID): You’ll isolate pure domain logic and abstract data sources behind stable interfaces.
- [ ] Error normalization strategy: You’ll standardize error shapes and transform them for user-friendly messages.

## Module C — Components and Signals
- [ ] Signals for local state and derivations: You’ll manage component-local state and derived values using signals.
- [ ] Signals–RxJS interop: You’ll bridge observables to signals (and back) without leaks or double subscriptions.
- [ ] Efficient change detection with OnPush: You’ll prevent unnecessary checks and renders with signals and careful bindings.
- [ ] Rendering large lists (CDK Virtual Scroll): You’ll efficiently render and interact with large collections using trackBy and virtualization.
- [ ] Memory leak clinic (subscriptions/cleanup): You’ll eliminate leaks using takeUntilDestroyed and disciplined subscription patterns.
- [ ] Accessibility fundamentals: You’ll make components keyboard- and screen-reader-friendly with minimal overhead.

## Module D — Pragmatic RxJS for Angular
- [ ] Core operator toolkit: You’ll apply a reliable subset of operators for UI flows and side effects.
- [ ] Concurrency semantics (switch/concat/exhaust/merge): You’ll pick the right operator based on user intent and UX semantics.
- [ ] Shared caching streams and invalidation: You’ll share results safely and refresh cache without duplication or thundering herds.
- [ ] Cancellation patterns and lifecycles: You’ll cancel in-flight work on navigation or destroy events correctly.
- [ ] Time-based control (debounce, throttle, jittered retry): You’ll implement responsive UI and resilient retry logic.

## Module E — State Management (Component Store + NgRx Store)
- [ ] Component Store basics: You’ll model feature-local state with typed updaters, selectors, and effects.
- [ ] Component Store pitfalls: You’ll avoid stale snapshots, racing effects, and nested mutations.
- [ ] NgRx Store setup for global concerns: You’ll manage cross-feature state like session/auth and user settings.
- [ ] Entity adapter and memoized selectors: You’ll normalize collections and query them efficiently at scale.
- [ ] Effects patterns and error handling: You’ll orchestrate side effects with cancellation and robust error handling.
- [ ] Optimistic updates and rollback: You’ll deliver snappy UX with safe speculative updates and compensation.
- [ ] Testing reducers, selectors, and effects: You’ll write reliable tests for state behavior and side effects.

## Module F — Data Access and HTTP
- [ ] OpenAPI/NSwag client generation: You’ll consume a strongly-typed API client in feature data-access layers.
- [ ] Interceptor chain (auth, ETag, retry, errors): You’ll centralize token injection, concurrency control, and error normalization.
- [ ] Caching strategies (SWR and cache-control): You’ll serve fast views while keeping data reasonably fresh.
- [ ] Pagination, sorting, filtering: You’ll implement scalable list UIs and network-efficient queries.
- [ ] File upload/download with progress and cancel: You’ll build resilient file flows with user feedback and cancellation.
- [ ] HAL/HATEOAS overview (light touch): You’ll understand link-driven navigation and when to apply it in REST (deep dive separate).
- [ ] 412 Precondition Failed lab (ETag/If-Match): You’ll resolve optimistic concurrency conflicts with clear UX.

## Module G — Authentication and Authorization
- [ ] OIDC/JWT overview with ASP.NET Core concepts: You’ll authenticate users and manage tokens safely in a SPA.
- [ ] Token refresh and silent renew: You’ll implement a single-flight refresh with queued request replay to avoid storms.
- [ ] Route protection with canMatch and claims: You’ll enforce access control with guards and route metadata.
- [ ] Auth interceptor and race-proof queueing: You’ll ensure blocked requests resume correctly after token refresh.
- [ ] Role/claim-based UI (structural directives/pipes): You’ll show/hide UI elements securely based on authorization context.
- [ ] Session persistence and logout flows: You’ll handle expiration, logout, and forced re-auth gracefully.
- [ ] E2E auth scenarios with Playwright: You’ll validate protected flows including silent renew and refresh.

## Module H — Routing and Performance (SPA)
- [ ] Advanced routing and lazy loading: You’ll split features cleanly and preload strategically.
- [ ] Data prefetch trade-offs: You’ll choose between resolvers and in-component prefetch with proper cancellation and error UX.
- [ ] Deferrable views and progressive rendering: You’ll defer non-critical content for faster perceived performance.
- [ ] SEO and shareability in SPA: You’ll manage titles/metas, Open Graph/Twitter tags, and sitemaps within SPA constraints.
- [ ] Performance budgets and bundle analysis: You’ll set and enforce budgets and analyze regressions.
- [ ] Navigation race/memory leak lab: You’ll fix leaks and flicker caused by late emissions during routing.

## Module I — Forms and Validation
- [ ] Strongly-typed reactive forms: You’ll architect scalable forms with end-to-end typing.
- [ ] Async validators with cancellation: You’ll avoid stale validations and race conditions.
- [ ] Dynamic forms and complex arrays: You’ll build maintainable dynamic structures and arrays.
- [ ] Accessible error patterns and focus management: You’ll deliver usable error feedback and focus control.
- [ ] valueChanges storm control: You’ll throttle and partition updates to keep forms responsive.

## Module J — Testing Deep Dives
- [ ] Angular Testing Library patterns: You’ll write user-centric tests that resist implementation churn.
- [ ] Storybook stories and interaction tests: You’ll document states and automate common interactions for visual confidence.
- [ ] Jest unit tests with time control: You’ll make async logic deterministic using fake timers and schedulers.
- [ ] Integration tests driving NgRx and HTTP: You’ll validate realistic feature flows without flakiness.
- [ ] Playwright best practices (network, tracing, retries): You’ll stabilize E2E suites with robust tooling.
- [ ] Testing anti-patterns clinic: You’ll identify and fix brittle, redundant, or slow tests.

## Module K — Observability, Security, and Operations
- [ ] Centralized logging and global error handling: You’ll normalize and surface errors for developers and users.
- [ ] Runtime configuration and feature flags: You’ll vary behavior by environment without rebuilds.
- [ ] UX performance monitoring (Web Vitals): You’ll measure and act on real-user performance data.
- [ ] Security headers and CSP for SPA: You’ll harden the SPA against XSS and related threats with minimal friction.
- [ ] Upgrades and maintenance: You’ll keep Angular and dependencies current with minimal disruption.

## Module L — Advanced and Optional
- [ ] Zoneless change detection (optional): You’ll evaluate migrating away from Zone.js and outline a plan.
- [ ] Web Workers for CPU-heavy tasks: You’ll offload expensive work to maintain UI responsiveness.
- [ ] Real-time updates with SignalR: You’ll integrate push models coherently with existing state and caching.
- [ ] Internationalization (i18n) at scale: You’ll localize features and manage translations efficiently.
- [ ] Micro-frontends vs. single app (conceptual): You’ll analyze when and how to split apps without adopting Nx.

## Capstone
- [ ] End-to-end book e-commerce checkout (SPA): You’ll deliver a fully tested, performant, secure cart/checkout flow with CI quality gates passing.