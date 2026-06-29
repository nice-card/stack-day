# AGENTS.md

# Stack Day

Stack Day is a habit-tracking app that helps users build consistency through small daily actions.

Unlike a traditional todo app, Stack Day focuses on habits users want to repeat every day—such as exercising, reading, drinking water, or meditating. The goal is to create a calm and lightweight experience that encourages consistency rather than productivity.

---

# Technology

- Swift 6
- SwiftUI
- Swift Concurrency (`async`/`await`, `actor`)
- Swift Testing

---

# Architecture

Follow MVVM with UseCases and the Repository pattern.

```
View
    ↓
ViewModel
    ↓
UseCase
    ↓
Repository
```

General principles:

- Keep Views declarative.
- Keep ViewModels responsible for UI state.
- Put business logic inside UseCases.
- Isolate persistence behind Repositories.
- Prefer composition over inheritance.

---

# Engineering Principles

- Follow SOLID principles.
- Prefer explicit code over magic.
- Avoid unnecessary abstraction.
- Keep layers meaningful.
- Keep functions small and focused.
- Prefer readability over cleverness.
- Keep dependencies minimal.

Do not introduce:

- unnecessary protocols
- unnecessary generic abstractions
- unnecessary helper types
- unnecessary third-party libraries

Every abstraction should solve a real problem.

---

# Swift Concurrency

- Prefer async/await.
- Use actors only when shared mutable state requires isolation.
- Keep synchronous work synchronous.
- Mark UI-facing ViewModels with `@MainActor` where appropriate.

---

# Testing

Practice TDD whenever practical.

Use Swift Testing.

Prioritize tests for:

- UseCases
- ViewModels
- Repository behavior
- Business rules
- Date and streak calculations

Avoid testing implementation details.

---

# AI Guidance

Before making changes:

- Read the existing implementation first.
- Understand the surrounding architecture.
- Follow existing patterns.
- Make the smallest reasonable change.
- Do not refactor unrelated code.
- Do not rename types unless necessary.

When implementing features:

- Prefer simple solutions.
- Do not over-engineer.
- Do not add new dependencies without a clear reason.
- Do not create placeholder implementations unless requested.

When the architecture is unclear:

- Match the existing codebase instead of inventing a new pattern.
- Preserve consistency across the project.

After completing a task:

- Ensure the project still builds.
- Update or add tests when behavior changes.
- Briefly explain important design decisions and trade-offs.
