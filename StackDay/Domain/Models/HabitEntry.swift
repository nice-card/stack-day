//
//  HabitEntry.swift
//  StackDay
//

import Foundation

struct HabitEntry: Equatable {
    enum State: Equatable {
        case pending
        case completed
        case missed
    }

    let habitID: UUID
    let targetDate: Date
    let state: State

    init(
        habit: Habit,
        targetDate: Date,
        completion: Completion?,
        referenceDate: Date
    ) throws {
        guard targetDate >= habit.startedOn else {
            throw HabitEntryError.beforeHabitStart
        }
        guard targetDate <= referenceDate else {
            throw HabitEntryError.futureDate
        }
        if let archivedOn = habit.archivedOn, targetDate > archivedOn {
            throw HabitEntryError.afterHabitArchived
        }

        habitID = habit.id
        self.targetDate = targetDate

        if completion != nil {
            state = .completed
        } else if targetDate == referenceDate {
            state = .pending
        } else {
            state = .missed
        }
    }
}

enum HabitEntryError: Error, Equatable {
    case beforeHabitStart
    case futureDate
    case afterHabitArchived
}
