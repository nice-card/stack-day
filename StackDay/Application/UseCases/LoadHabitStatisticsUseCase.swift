//
//  LoadHabitStatisticsUseCase.swift
//  StackDay
//

import Foundation

struct LoadHabitStatisticsUseCase {
    private let habitRepository: any HabitRepository
    private let completionRepository: any CompletionRepository
    private let clock: any Clock
    private let timeZone: TimeZone

    init(
        habitRepository: any HabitRepository,
        completionRepository: any CompletionRepository,
        clock: any Clock,
        timeZone: TimeZone = .current
    ) {
        self.habitRepository = habitRepository
        self.completionRepository = completionRepository
        self.clock = clock
        self.timeZone = timeZone
    }

    func execute(habitID: Habit.ID) async throws -> HabitStatistics {
        guard let habit = try await habitRepository.fetch(id: habitID) else {
            throw LoadHabitStatisticsError.habitNotFound
        }

        let completions = try await completionRepository.fetchAll(for: habit.id)
        let referenceDay = try LocalDay(date: clock.now, timeZone: timeZone)

        return try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions,
            referenceDay: referenceDay
        )
    }
}

enum LoadHabitStatisticsError: Error, Equatable {
    case habitNotFound
}
