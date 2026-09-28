//
//  LoadStatisticsOverviewUseCase.swift
//  StackDay
//
//  Created by Kelly Dev on 9/9/26.
//

import Foundation

struct LoadStatisticsOverviewUseCase {
    private let habitRepository: any HabitRepository
    private let completionRepository: any CompletionRepository
    private let calculator: HabitStatisticsCalculator
    private let clock: any Clock
    private let timeZone: TimeZone

    init(
        habitRepository: any HabitRepository,
        completionRepository: any CompletionRepository,
        calculator: HabitStatisticsCalculator,
        clock: any Clock,
        timeZone: TimeZone
    ) {
        self.habitRepository = habitRepository
        self.completionRepository = completionRepository
        self.calculator = calculator
        self.clock = clock
        self.timeZone = timeZone
    }

    func execute() async throws -> [HabitStatisticsSummary] {
        let referenceDay = try LocalDay(
            date: clock.now,
            timeZone: timeZone
        )
        var summaries = [HabitStatisticsSummary]()
        
        let habits = try await habitRepository.fetchAll()
        for habit in habits {
            let completions = try await completionRepository.fetchAll(for: habit.id)
            let eligibleDays = try habit.trackingDays(through: referenceDay)
            let eligibleDaySet = Set(eligibleDays)
            let completedDays = Set(completions.map(\.completedOn))
                .intersection(eligibleDaySet)
            let summary = HabitStatisticsSummary(
                id: habit.id,
                name: habit.name,
                isArchived: habit.isArchived,
                currentStreak: calculator.currentStreak(
                    eligibleDays: eligibleDays,
                    completedDays: completedDays,
                    referenceDay: referenceDay
                ),
                completionRate: calculator.completionRate(
                    completedDayCount: completedDays.count,
                    eligibleDayCount: eligibleDays.count
                )
            )
            summaries.append(summary)
        }
        return summaries
    }
}

