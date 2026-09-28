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
        try habit.validateDate(targetDate, referenceDate: referenceDate)

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
