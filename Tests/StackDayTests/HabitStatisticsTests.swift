//
//  HabitStatisticsTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct HabitStatisticsTests {
    @Test("calculates completion rate from completed and eligible counts")
    func calculatesCompletionRate() {
        let rate = HabitStatisticsCalculator().completionRate(
            completedDayCount: 2,
            eligibleDayCount: 3
        )

        #expect(rate == 2.0 / 3.0)
    }

    @Test("returns zero completion rate without eligible days")
    func returnsZeroCompletionRateWithoutEligibleDays() {
        let rate = HabitStatisticsCalculator().completionRate(
            completedDayCount: 0,
            eligibleDayCount: 0
        )

        #expect(rate == 0)
    }

    @Test("calculates the current daily streak")
    func calculatesCurrentStreak() throws {
        let day1 = try day(2026, 1, 1)
        let day2 = try day(2026, 1, 2)
        let day3 = try day(2026, 1, 3)
        let day4 = try day(2026, 1, 4)
        let day5 = try day(2026, 1, 5)
        let day6 = try day(2026, 1, 6)

        let streak = HabitStatisticsCalculator().currentStreak(
            eligibleDays: [day1, day2, day3, day4, day5, day6],
            completedDays: [day1, day2, day3, day5, day6],
            referenceDay: day6
        )

        #expect(streak == 2)
    }

    @Test("keeps the current streak when the reference day is incomplete")
    func keepsCurrentStreakWhenReferenceDayIsIncomplete() throws {
        let day1 = try day(2026, 1, 1)
        let day2 = try day(2026, 1, 2)
        let referenceDay = try day(2026, 1, 3)

        let streak = HabitStatisticsCalculator().currentStreak(
            eligibleDays: [day1, day2, referenceDay],
            completedDays: [day1, day2],
            referenceDay: referenceDay
        )

        #expect(streak == 2)
    }

    @Test("ends the current streak at a missed past eligible date")
    func endsCurrentStreakAtPastMiss() throws {
        let day1 = try day(2026, 1, 1)
        let day2 = try day(2026, 1, 2)
        let day3 = try day(2026, 1, 3)
        let referenceDay = try day(2026, 1, 4)

        let streak = HabitStatisticsCalculator().currentStreak(
            eligibleDays: [day1, day2, day3, referenceDay],
            completedDays: [day1, day2],
            referenceDay: referenceDay
        )

        #expect(streak == 0)
    }

    @Test("calculates the longest daily streak")
    func calculatesLongestStreak() throws {
        let day1 = try day(2025, 12, 31)
        let day2 = try day(2026, 1, 1)
        let day3 = try day(2026, 1, 2)
        let day4 = try day(2026, 1, 3)
        let day5 = try day(2026, 1, 4)

        let streak = HabitStatisticsCalculator().longestStreak(
            eligibleDays: [day1, day2, day3, day4, day5],
            completedDays: [day1, day2, day3, day5]
        )

        #expect(streak == 3)
    }

    @Test("calculates streaks across separated eligible date ranges")
    func calculatesStreakAcrossSeparatedEligibleDateRanges() throws {
        let firstDay = try day(2026, 1, 1)
        let resumedDay = try day(2026, 1, 3)

        let streak = HabitStatisticsCalculator().longestStreak(
            eligibleDays: [firstDay, resumedDay],
            completedDays: [firstDay, resumedDay]
        )

        #expect(streak == 2)
    }

    @Test("calculates the current streak across separated eligible date ranges")
    func calculatesCurrentStreakAcrossSeparatedEligibleDateRanges() throws {
        let firstDay = try day(2026, 1, 1)
        let resumedDay = try day(2026, 1, 3)

        let streak = HabitStatisticsCalculator().currentStreak(
            eligibleDays: [firstDay, resumedDay],
            completedDays: [firstDay, resumedDay],
            referenceDay: resumedDay
        )

        #expect(streak == 2)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> LocalDay {
        try LocalDay(year: year, month: month, day: day)
    }
}
