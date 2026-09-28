//
//  ArchiveHabitUseCase.swift
//  StackDay
//

import Foundation

struct ArchiveHabitUseCase {
    private let habitRepository: any HabitRepository
    private let completionRepository: any CompletionRepository
    private let clock: any Clock
    private let timeZone: TimeZone

    init(
        habitRepository: any HabitRepository,
        completionRepository: any CompletionRepository,
        clock: any Clock,
        timeZone: TimeZone
    ) {
        self.habitRepository = habitRepository
        self.completionRepository = completionRepository
        self.clock = clock
        self.timeZone = timeZone
    }

    func execute(habitID: Habit.ID) async throws -> Habit {
        guard var habit = try await habitRepository.fetch(id: habitID) else {
            throw ArchiveHabitError.habitNotFound
        }

        let now = clock.now
        let archiveDay = try LocalDay(date: now, timeZone: timeZone)
        let effectiveArchivedOn = if try await completionRepository.fetch(
            habitID: habitID,
            completedOn: archiveDay
        ) != nil {
            archiveDay
        } else {
            try archiveDay.addingDays(-1)
        }

        try habit.archive(
            on: archiveDay,
            effectiveArchivedOn: effectiveArchivedOn,
            updatedAt: now
        )
        try await habitRepository.update(habit)
        return habit
    }
}

enum ArchiveHabitError: Error, Equatable {
    case habitNotFound
}
