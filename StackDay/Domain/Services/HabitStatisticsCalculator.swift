//
//  HabitStatisticsCalculator.swift
//  StackDay
//

import Foundation

struct HabitStatisticsCalculator {
    func calculate(
        habit: Habit,
        completions: [Completion],
        referenceDay: LocalDay
    ) throws -> HabitStatistics {
        let startDay = habit.startedOn
        let lastTrackedDay = min(
            referenceDay,
            habit.archivedOn ?? referenceDay
        )
        let eligibleTrackingDays = try trackingDayCount(
            from: startDay,
            through: lastTrackedDay
        )
        let completedDays = completedDays(
            for: habit,
            in: completions,
            from: startDay,
            through: lastTrackedDay
        )
        let totalCompletedDays = completedDays.count
        let completionRate = eligibleTrackingDays == 0
            ? 0
            : Double(totalCompletedDays) / Double(eligibleTrackingDays)
        let streak = try calculateStreak(
            from: startDay,
            through: lastTrackedDay,
            referenceDay: referenceDay,
            completedDays: completedDays
        )

        return HabitStatistics(
            totalCompletedDays: totalCompletedDays,
            eligibleTrackingDays: eligibleTrackingDays,
            completionRate: completionRate,
            streak: streak
        )
    }

    private func trackingDayCount(
        from startDate: LocalDay,
        through lastTrackedDay: LocalDay
    ) throws -> Int {
        guard startDate <= lastTrackedDay else { return 0 }
        var count = 1
        var date = startDate
        while date < lastTrackedDay {
            date = try date.addingDays(1)
            count += 1
        }
        return count
    }

    private func calculateStreak(
        from startDate: LocalDay,
        through lastTrackedDay: LocalDay,
        referenceDay: LocalDay,
        completedDays: Set<LocalDay>
    ) throws -> HabitStreak {
        guard startDate <= lastTrackedDay else {
            return HabitStreak(current: 0, longest: 0)
        }

        var longest = 0
        var consecutiveDays = 0
        var date = startDate

        while date <= lastTrackedDay {
            if completedDays.contains(date) {
                consecutiveDays += 1
                longest = max(longest, consecutiveDays)
            } else {
                consecutiveDays = 0
            }
            date = try date.addingDays(1)
        }

        var current = 0
        var currentDate = lastTrackedDay
        if lastTrackedDay == referenceDay, !completedDays.contains(referenceDay) {
            currentDate = try currentDate.addingDays(-1)
        }

        while currentDate >= startDate, completedDays.contains(currentDate) {
            current += 1
            currentDate = try currentDate.addingDays(-1)
        }

        return HabitStreak(current: current, longest: longest)
    }

    private func completedDays(
        for habit: Habit,
        in completions: [Completion],
        from startDate: LocalDay,
        through lastTrackedDay: LocalDay
    ) -> Set<LocalDay> {
        Set(completions.compactMap { completion in
            guard completion.habitID == habit.id else { return nil }
            let completedDay = completion.completedOn
            guard completedDay >= startDate, completedDay <= lastTrackedDay else {
                return nil
            }
            return completedDay
        })
    }
}
