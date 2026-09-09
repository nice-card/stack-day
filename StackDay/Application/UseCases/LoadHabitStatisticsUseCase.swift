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
        timeZone: TimeZone
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
        let eligibleDays = try habit.trackingDays(through: referenceDay)
        let eligibleDaySet = Set(eligibleDays)
        let completedDays = Set(completions.map(\.completedOn))
            .intersection(eligibleDaySet)
        let totalCompletedDays = completedDays.count
        let eligibleTrackingDays = eligibleDays.count
        let calculator = HabitStatisticsCalculator()
        let currentStreak = calculator.currentStreak(
            eligibleDays: eligibleDays,
            completedDays: completedDays,
            referenceDay: referenceDay
        )
        let longestStreak = calculator.longestStreak(
            eligibleDays: eligibleDays,
            completedDays: completedDays
        )
        let completionRate = calculator.completionRate(
            completedDayCount: totalCompletedDays,
            eligibleDayCount: eligibleTrackingDays
        )

        return HabitStatistics(
            totalCompletedDays: totalCompletedDays,
            eligibleTrackingDays: eligibleTrackingDays,
            completionRate: completionRate,
            streak: HabitStreak(
                current: currentStreak,
                longest: longestStreak
            )
        )
    }
}

enum LoadHabitStatisticsError: Error, Equatable {
    case habitNotFound
}
