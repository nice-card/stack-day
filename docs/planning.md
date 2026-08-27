# Development Goals

The implementation should demonstrate clear product and engineering decisions
without adding complexity that the product does not need.

## Technical goals

- Build a SwiftUI app with clear, traceable state flow.
- Keep UI, application behavior, domain logic, and persistence separate.
- Make date and streak calculations independently testable.
- Keep persisted source data distinct from derived values.
- Preserve data across app relaunches with local storage.
- Keep the UI calm, responsive, accessible, and usable in dark mode.

## Completion criteria

The MVP is complete when:

- A completion survives app relaunch.
- Today and Statistics views stay consistent after a record changes.
- Editing a past record recalculates streaks and statistics.
- Creating, renaming, archiving, and deleting a habit updates affected views
  and statistics consistently.
- Date boundaries such as midnight, month-end, year-end, and an archive date
  with and without a completion are tested.
- Empty, first-habit, and first-completion flows are usable.
- Core interactions work with Dynamic Type and dark mode.
