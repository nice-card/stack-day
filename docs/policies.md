# MVP Policies

This document records product decisions that implementation and tests must
follow. It describes behavior, not a particular type or storage framework.

## Recording dates

- Future dates cannot be recorded or edited.
- Dates before a habit's start date cannot be recorded or edited.
- Past completion records can be added or canceled.
- A habit can have at most one completion for a given date.

## Habit creation

- A habit name is trimmed of leading and trailing whitespace and newlines, and
  cannot be empty after trimming.
- A habit starts on the date selected when it is created. A habit may be
  created with a past or future start date.

## Habit editing

- The only editable habit definition in the MVP is its name.
- Renaming follows the same trimming and non-empty validation as creation.
- A habit's start date cannot be changed.

## Today

- The Today screen shows habits scheduled for today.
- Past incomplete dates are not carried onto the Today screen.
- An incomplete habit for today does not break the current streak while the
  day is still in progress.
- If the day ends without a completion, the next calculation treats it as a
  missed day.

## Streaks and statistics

- The MVP uses a strict daily streak.
- Only scheduled dates are considered when calculating streaks.
- Current streak and longest streak are calculated from completion history.
- Completion rate is based on completed dates and eligible dates.
- Changes to past records recalculate affected statistics.

## Habit lifecycle

- A habit owns one or more non-overlapping tracking periods. The first period
  starts when the habit is created.
- Archiving ends the current period. The archive date is included when it has
  a completion at that time; otherwise the period ends on the preceding day.
- DayView shows an entry only for dates inside a tracking period. An incomplete
  archive date is therefore absent from DayView; a completed archive date
  remains visible for that date. Dates outside a tracking period cannot receive
  completion records and are excluded from statistics.
- Unarchiving starts a new tracking period on the current date. When that
  would leave no excluded date between periods, the periods are merged instead.
  Same-day archive and unarchive therefore leave no tracking-period history.
- Existing completion history remains available. Statistics include only dates
  in tracking periods.
- Deleting a habit permanently deletes it and its related completion records.

## Heatmap

- A monthly heatmap displays a cell for every date in the selected month.
- Future dates and dates outside a habit's tracking period appear as empty
  cells without a completion or missed state.

## Out of scope for the MVP

- Selected weekday schedules
- Protected streaks or streak allowances
- Resuming archived habits or multiple tracking periods
- Count-based, total-based, and timer-based habits
- Notifications, widgets, accounts, servers, cloud sync, and social features
