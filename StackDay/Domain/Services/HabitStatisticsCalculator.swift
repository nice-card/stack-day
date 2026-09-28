//
//  HabitStatisticsCalculator.swift
//  StackDay
//

import Foundation

struct HabitStatisticsCalculator {
    func currentStreak(
        eligibleDays: [LocalDay],
        completedDays: Set<LocalDay>,
        referenceDay: LocalDay
    ) -> Int {
        let shouldExcludeToday = eligibleDays.last == referenceDay && !completedDays.contains(referenceDay)
        let currentStreakDays = eligibleDays.dropLast(shouldExcludeToday ? 1 : 0)
        var current = 0
        for day in currentStreakDays.reversed() {
            guard completedDays.contains(day) else { break }
            current += 1
        }
        return current
    }

    func longestStreak(
        eligibleDays: [LocalDay],
        completedDays: Set<LocalDay>
    ) -> Int {
        var longest = 0
        var consecutiveDays = 0
        for date in eligibleDays {
            if completedDays.contains(date) {
                consecutiveDays += 1
                longest = max(longest, consecutiveDays)
            } else {
                consecutiveDays = 0
            }
        }
        return longest
    }

    func completionRate(
        completedDayCount: Int,
        eligibleDayCount: Int
    ) -> Double {
        guard eligibleDayCount > 0 else { return 0 }
        return Double(completedDayCount) / Double(eligibleDayCount)
    }
}
