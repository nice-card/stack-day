//
//  RenameHabitUseCase.swift
//  StackDay
//

import Foundation

struct RenameHabitUseCase {
    private let habitRepository: any HabitRepository
    private let clock: any Clock

    init(habitRepository: any HabitRepository, clock: any Clock) {
        self.habitRepository = habitRepository
        self.clock = clock
    }

    func execute(habitID: Habit.ID, name: String) async throws -> Habit {
        guard var habit = try await habitRepository.fetch(id: habitID) else {
            throw RenameHabitError.habitNotFound
        }

        try habit.rename(to: name, updatedAt: clock.now)
        try await habitRepository.update(habit)
        return habit
    }
}

enum RenameHabitError: Error, Equatable {
    case habitNotFound
}
