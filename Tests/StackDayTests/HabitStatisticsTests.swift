//
//  HabitStatisticsTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct HabitStatisticsTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("calculates completed days, eligible days, and completion rate")
    func calculatesCompletionStatistics() throws {
        let habit = try makeHabit(startedOn: date(2026, 1, 1))
        let statistics = HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(for: habit, on: [date(2026, 1, 1), date(2026, 1, 3)]),
            referenceDate: date(2026, 1, 3),
            calendar: calendar
        )

        #expect(statistics.totalCompletedDays == 2)
        #expect(statistics.eligibleTrackingDays == 3)
        #expect(statistics.completionRate == 2.0 / 3.0)
    }

    @Test("includes an incomplete reference day as eligible")
    func includesIncompleteReferenceDay() throws {
        let habit = try makeHabit(startedOn: date(2026, 1, 1))
        let statistics = HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(for: habit, on: [date(2026, 1, 1)]),
            referenceDate: date(2026, 1, 2),
            calendar: calendar
        )

        #expect(statistics.totalCompletedDays == 1)
        #expect(statistics.eligibleTrackingDays == 2)
        #expect(statistics.completionRate == 0.5)
    }

    @Test("counts dates across month and year boundaries")
    func countsAcrossDateBoundaries() throws {
        let habit = try makeHabit(startedOn: date(2025, 12, 31))
        let statistics = HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(for: habit, on: [
                date(2025, 12, 31), date(2026, 1, 2)
            ]),
            referenceDate: date(2026, 1, 2),
            calendar: calendar
        )

        #expect(statistics.eligibleTrackingDays == 3)
        #expect(statistics.totalCompletedDays == 2)
        #expect(statistics.completionRate == 2.0 / 3.0)
    }

    @Test("uses an archived habit's inclusive final tracking date")
    func usesArchivedFinalTrackingDate() throws {
        let archiveDate = date(2026, 1, 2)
        let habit = try makeHabit(startedOn: date(2026, 1, 1), archivedOn: archiveDate)
        let statistics = HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(for: habit, on: [
                date(2026, 1, 1), archiveDate, date(2026, 1, 3)
            ]),
            referenceDate: date(2026, 1, 4),
            calendar: calendar
        )

        #expect(statistics.eligibleTrackingDays == 2)
        #expect(statistics.totalCompletedDays == 2)
        #expect(statistics.completionRate == 1)
    }

    @Test("calculates current and longest daily streaks")
    func calculatesCurrentAndLongestStreaks() throws {
        let habit = try makeHabit(startedOn: date(2026, 1, 1))
        let statistics = HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(for: habit, on: [
                date(2026, 1, 1), date(2026, 1, 2), date(2026, 1, 3),
                date(2026, 1, 5), date(2026, 1, 6)
            ]),
            referenceDate: date(2026, 1, 6),
            calendar: calendar
        )

        #expect(statistics.streak.current == 2)
        #expect(statistics.streak.longest == 3)
    }

    @Test("keeps the current streak when today is incomplete")
    func keepsCurrentStreakWhenTodayIsIncomplete() throws {
        let habit = try makeHabit(startedOn: date(2026, 1, 1))
        let statistics = HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(for: habit, on: [date(2026, 1, 1), date(2026, 1, 2)]),
            referenceDate: date(2026, 1, 3),
            calendar: calendar
        )

        #expect(statistics.streak == HabitStreak(current: 2, longest: 2))
    }

    @Test("ends the current streak at a missed past eligible date")
    func pastMissEndsCurrentStreak() throws {
        let habit = try makeHabit(startedOn: date(2026, 1, 1))
        let statistics = HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(for: habit, on: [date(2026, 1, 1), date(2026, 1, 2)]),
            referenceDate: date(2026, 1, 4),
            calendar: calendar
        )

        #expect(statistics.streak == HabitStreak(current: 0, longest: 2))
    }

    @Test("calculates streaks across year and month boundaries")
    func streakCrossesDateBoundaries() throws {
        let habit = try makeHabit(startedOn: date(2025, 12, 31))
        let statistics = HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(for: habit, on: [
                date(2025, 12, 31), date(2026, 1, 1), date(2026, 1, 2)
            ]),
            referenceDate: date(2026, 1, 2),
            calendar: calendar
        )

        #expect(statistics.streak == HabitStreak(current: 3, longest: 3))
    }

    @Test("uses an archived habit's final tracking date for streaks")
    func streakUsesArchivedFinalTrackingDate() throws {
        let archiveDate = date(2026, 1, 2)
        let habit = try makeHabit(startedOn: date(2026, 1, 1), archivedOn: archiveDate)
        let statistics = HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: completions(for: habit, on: [date(2026, 1, 1), archiveDate]),
            referenceDate: date(2026, 1, 4),
            calendar: calendar
        )

        #expect(statistics.streak == HabitStreak(current: 2, longest: 2))
    }
    
    @Test("returns zero statistics before the habit starts")
    func returnsZeroBeforeHabitStart() throws {
        let habit = try makeHabit(startedOn: date(2026, 1, 2))

        let statistics = HabitStatisticsCalculator().calculate(
            habit: habit,
            completions: [],
            referenceDate: date(2026, 1, 1),
            calendar: calendar
        )

        #expect(statistics.totalCompletedDays == 0)
        #expect(statistics.eligibleTrackingDays == 0)
        #expect(statistics.completionRate == 0)
        #expect(statistics.streak == HabitStreak(current: 0, longest: 0))
    }

    private func makeHabit(startedOn: Date, archivedOn: Date? = nil) throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: startedOn,
            archivedOn: archivedOn,
            createdAt: startedOn
        )
    }

    private func completions(for habit: Habit, on dates: [Date]) -> [Completion] {
        dates.map { Completion(habitID: habit.id, completedOn: $0, recordedAt: $0) }
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
