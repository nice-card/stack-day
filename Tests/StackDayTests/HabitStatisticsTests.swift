//
//  HabitStatisticsTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct HabitStatisticsTests {
    private let recordedAt = Date(timeIntervalSince1970: 0)

    @Test("calculates completed days, eligible days, and completion rate")
    func calculatesCompletionStatistics() throws {
        let startDay = try day(2026, 1, 1)
        let referenceDay = try day(2026, 1, 3)
        let habit = try makeHabit(startedOn: startDay)

        let statistics = try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(
                for: habit,
                on: [startDay, referenceDay]
            ),
            referenceDay: referenceDay
        )

        #expect(statistics.totalCompletedDays == 2)
        #expect(statistics.eligibleTrackingDays == 3)
        #expect(statistics.completionRate == 2.0 / 3.0)
    }

    @Test("includes an incomplete reference day as eligible")
    func includesIncompleteReferenceDay() throws {
        let startDay = try day(2026, 1, 1)
        let referenceDay = try day(2026, 1, 2)
        let habit = try makeHabit(startedOn: startDay)

        let statistics = try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(
                for: habit,
                on: [startDay]
            ),
            referenceDay: referenceDay
        )

        #expect(statistics.totalCompletedDays == 1)
        #expect(statistics.eligibleTrackingDays == 2)
        #expect(statistics.completionRate == 0.5)
    }

    @Test("counts dates across month and year boundaries")
    func countsAcrossDateBoundaries() throws {
        let startDay = try day(2025, 12, 31)
        let referenceDay = try day(2026, 1, 2)
        let habit = try makeHabit(startedOn: startDay)

        let statistics = try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(
                for: habit,
                on: [startDay, referenceDay]
            ),
            referenceDay: referenceDay
        )

        #expect(statistics.eligibleTrackingDays == 3)
        #expect(statistics.totalCompletedDays == 2)
        #expect(statistics.completionRate == 2.0 / 3.0)
    }

    @Test("uses an archived habit's inclusive final tracking date")
    func usesArchivedFinalTrackingDate() throws {
        let startDay = try day(2026, 1, 1)
        let archiveDay = try day(2026, 1, 2)
        let completionAfterArchive = try day(2026, 1, 3)
        let referenceDay = try day(2026, 1, 4)

        let habit = try makeHabit(
            startedOn: startDay,
            archivedOn: archiveDay
        )

        let statistics = try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(
                for: habit,
                on: [
                    startDay,
                    archiveDay,
                    completionAfterArchive
                ]
            ),
            referenceDay: referenceDay
        )

        #expect(statistics.eligibleTrackingDays == 2)
        #expect(statistics.totalCompletedDays == 2)
        #expect(statistics.completionRate == 1)
    }

    @Test("calculates current and longest daily streaks")
    func calculatesCurrentAndLongestStreaks() throws {
        let day1 = try day(2026, 1, 1)
        let day2 = try day(2026, 1, 2)
        let day3 = try day(2026, 1, 3)
        let day5 = try day(2026, 1, 5)
        let day6 = try day(2026, 1, 6)

        let habit = try makeHabit(startedOn: day1)

        let statistics = try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(
                for: habit,
                on: [day1, day2, day3, day5, day6]
            ),
            referenceDay: day6
        )

        #expect(statistics.streak.current == 2)
        #expect(statistics.streak.longest == 3)
    }

    @Test("keeps the current streak when today is incomplete")
    func keepsCurrentStreakWhenTodayIsIncomplete() throws {
        let day1 = try day(2026, 1, 1)
        let day2 = try day(2026, 1, 2)
        let referenceDay = try day(2026, 1, 3)

        let habit = try makeHabit(startedOn: day1)

        let statistics = try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(
                for: habit,
                on: [day1, day2]
            ),
            referenceDay: referenceDay
        )

        #expect(
            statistics.streak == HabitStreak(
                current: 2,
                longest: 2
            )
        )
    }

    @Test("ends the current streak at a missed past eligible date")
    func pastMissEndsCurrentStreak() throws {
        let day1 = try day(2026, 1, 1)
        let day2 = try day(2026, 1, 2)
        let referenceDay = try day(2026, 1, 4)

        let habit = try makeHabit(startedOn: day1)

        let statistics = try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(
                for: habit,
                on: [day1, day2]
            ),
            referenceDay: referenceDay
        )

        #expect(
            statistics.streak == HabitStreak(
                current: 0,
                longest: 2
            )
        )
    }

    @Test("calculates streaks across year and month boundaries")
    func streakCrossesDateBoundaries() throws {
        let day1 = try day(2025, 12, 31)
        let day2 = try day(2026, 1, 1)
        let day3 = try day(2026, 1, 2)

        let habit = try makeHabit(startedOn: day1)

        let statistics = try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(
                for: habit,
                on: [day1, day2, day3]
            ),
            referenceDay: day3
        )

        #expect(
            statistics.streak == HabitStreak(
                current: 3,
                longest: 3
            )
        )
    }

    @Test("uses an archived habit's final tracking date for streaks")
    func streakUsesArchivedFinalTrackingDate() throws {
        let startDay = try day(2026, 1, 1)
        let archiveDay = try day(2026, 1, 2)
        let referenceDay = try day(2026, 1, 4)

        let habit = try makeHabit(
            startedOn: startDay,
            archivedOn: archiveDay
        )

        let statistics = try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(
                for: habit,
                on: [startDay, archiveDay]
            ),
            referenceDay: referenceDay
        )

        #expect(
            statistics.streak == HabitStreak(
                current: 2,
                longest: 2
            )
        )
    }

    @Test("returns zero statistics before the habit starts")
    func returnsZeroBeforeHabitStart() throws {
        let startDay = try day(2026, 1, 2)
        let referenceDay = try day(2026, 1, 1)

        let habit = try makeHabit(startedOn: startDay)

        let statistics = try HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: [],
            referenceDay: referenceDay
        )

        #expect(statistics.totalCompletedDays == 0)
        #expect(statistics.eligibleTrackingDays == 0)
        #expect(statistics.completionRate == 0)
        #expect(
            statistics.streak == HabitStreak(
                current: 0,
                longest: 0
            )
        )
    }

    private func makeHabit(
        startedOn: LocalDay,
        archivedOn: LocalDay? = nil
    ) throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: startedOn,
            archivedOn: archivedOn,
            createdAt: recordedAt
        )
    }

    private func completions(for habit: Habit, on days: [LocalDay]) -> [Completion] {
        days.map {
            Completion(
                habitID: habit.id,
                completedOn: $0,
                recordedAt: recordedAt
            )
        }
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> LocalDay {
        try LocalDay(
            year: year,
            month: month,
            day: day
        )
    }
}
