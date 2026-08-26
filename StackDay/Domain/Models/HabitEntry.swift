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
        case future
    }

    let habitID: UUID
    let habitName: String
    let targetDay: LocalDay
    let state: State

    init(
        habit: Habit,
        targetDay: LocalDay,
        completion: Completion?,
        referenceDay: LocalDay
    ) throws {
        habitID = habit.id
        habitName = habit.name
        self.targetDay = targetDay

        if completion != nil {
            state = .completed
        } else if targetDay > referenceDay {
            state = .future
        } else if targetDay == referenceDay {
            state = .pending
        } else {
            state = .missed
        }
    }
}
