# Stack Day Product

## One-line Definition

A calm habit-tracking app that helps users focus on today's practice and restart without pressure after missing a day.

## Core Principles

- Do not carry unfinished habits from the past into today's screen.
- Show the habits scheduled for today and make recording quick.
- Make it easy to return after missing a day.
- Show progress through streaks, completion rate, and a monthly heatmap.

## Habit Types

The product may eventually support different ways to measure a habit:

- Daily: whether the habit was completed that day
- Count-based: how many times it was performed
- Total-based: accumulated progress over a period
- Timer-based: how long a state has been maintained

The MVP supports only daily habits. The other types remain future direction,
not implementation requirements.

## MVP

The MVP supports daily habits with a strict streak policy.

- Create, rename, archive, unarchive, and permanently delete habits
- View habits scheduled for today
- Complete and uncomplete habits for today
- Add or cancel completion records for past dates
- View current streak, longest streak, total completed days, completion rate,
  and a monthly heatmap in the Statistics tab
- Persist data locally and restore it after relaunch

Future dates and dates before a habit's start date cannot be recorded or edited.

Archived habits are removed from today's screen. Their existing records and derived statistics remain available, and completion records within their fixed past tracking period can still be added or canceled. Unarchiving resumes tracking from the current date, creating a new tracking period when needed.

## Core Flow

Create or rename a habit → show it on today's screen → record a completion →
calculate streaks and statistics → review the Statistics tab → edit past
completion records

## Screens

The initial product can be covered by four screens:

- Today
- Habit creation/renaming
- Record editing
- Statistics

## Future Scope

The following are outside the MVP:

- Repeating habits on selected weekdays
- Changing a habit's start date
- Count-based, total-based, and timer-based habits
- Protected streaks and no-streak mode
- Cloud sync, social features, and reward systems
