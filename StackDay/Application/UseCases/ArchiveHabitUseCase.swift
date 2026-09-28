//
//  ArchiveHabitUseCase.swift
//  StackDay
//

import Foundation

struct ArchiveHabitUseCase {
    private let repository: any HabitRepository
    private let clock: any Clock
    private let timeZone: TimeZone

    init(repository: any HabitRepository, clock: any Clock, timeZone: TimeZone) {
        self.repository = repository
        self.clock = clock
        self.timeZone = timeZone
    }

    func execute(habitID: Habit.ID) async throws -> Habit {
        guard var habit = try await repository.fetch(id: habitID) else {
            throw ArchiveHabitError.habitNotFound
        }

        let now = clock.now
        try habit.archive(
            on: try LocalDay(date: now, timeZone: timeZone),
            updatedAt: now
        )
        try await repository.update(habit)
        return habit
    }
}

enum ArchiveHabitError: Error, Equatable {
    case habitNotFound
}
