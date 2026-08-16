//
//  ArchiveHabitUseCase.swift
//  StackDay
//

import Foundation

struct ArchiveHabitUseCase {
    private let repository: any HabitRepository
    private let now: () -> Date

    init(repository: any HabitRepository, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    func execute(habitID: Habit.ID) async throws -> Habit {
        guard var habit = try await repository.fetch(id: habitID) else {
            throw ArchiveHabitError.habitNotFound
        }

        try habit.archive(on: now())
        try await repository.update(habit)
        return habit
    }
}

enum ArchiveHabitError: Error, Equatable {
    case habitNotFound
}
