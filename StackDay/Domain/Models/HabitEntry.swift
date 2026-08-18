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
    let targetDay: LocalDay
    let state: State

    init(
        habit: Habit,
        targetDay: LocalDay,
        completion: Completion?,
        referenceDay: LocalDay
    ) throws {
        try habit.validateDate(targetDay, referenceDay: referenceDay)

        habitID = habit.id
        self.targetDay = targetDay

        if completion != nil {
            state = .completed
        } else if targetDay == referenceDay {
            state = .pending
        } else {
            state = .missed
        }
    }
}
