# MVP Policies

This document records product decisions that implementation and tests must
follow. It describes behavior, not a particular type or storage framework.

## Recording dates

- Future dates cannot be recorded or edited.
- Dates before a habit's start date cannot be recorded or edited.
- Past completion records can be added or canceled.
- A habit can have at most one completion for a given date.

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

- Archiving removes a habit from Today and stops future recording.
- Existing history and derived statistics remain available after archiving.
- Past records within the tracking period can still be edited after archive.
- Deleting a habit permanently deletes it and its related completion records.

## Out of scope for the MVP

- Selected weekday schedules
- Protected streaks or streak allowances
- Resuming archived habits or multiple tracking periods
- Count-based, total-based, and timer-based habits
- Notifications, widgets, accounts, servers, cloud sync, and social features
