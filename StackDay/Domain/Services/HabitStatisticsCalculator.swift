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
        let startDate = habit.startedOn
        let finalTrackingDate = min(
            referenceDay,
            habit.archivedOn ?? referenceDay
        )
        let eligibleTrackingDays = try trackingDayCount(
            from: startDate,
            through: finalTrackingDate
        )
        let completedDays = completedDays(
            for: habit,
            from: completions,
            from: startDate,
            through: finalTrackingDate
        )
        let totalCompletedDays = completedDays.count
        let completionRate = eligibleTrackingDays == 0
            ? 0
            : Double(totalCompletedDays) / Double(eligibleTrackingDays)
        let streak = try calculateStreak(
            from: startDate,
            through: finalTrackingDate,
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
        through finalTrackingDate: LocalDay
    ) throws -> Int {
        guard startDate <= finalTrackingDate else { return 0 }
        var count = 1
        var date = startDate
        while date < finalTrackingDate {
            date = try date.addingDays(1)
            count += 1
        }
        return count
    }

    private func calculateStreak(
        from startDate: LocalDay,
        through finalTrackingDate: LocalDay,
        referenceDay: LocalDay,
        completedDays: Set<LocalDay>
    ) throws -> HabitStreak {
        guard startDate <= finalTrackingDate else {
            return HabitStreak(current: 0, longest: 0)
        }

        var longest = 0
        var consecutiveDays = 0
        var date = startDate

        while date <= finalTrackingDate {
            if completedDays.contains(date) {
                consecutiveDays += 1
                longest = max(longest, consecutiveDays)
            } else {
                consecutiveDays = 0
            }
            date = try date.addingDays(1)
        }

        var current = 0
        var currentDate = finalTrackingDate
        if finalTrackingDate == referenceDay, !completedDays.contains(referenceDay) {
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
        from completions: [Completion],
        from startDate: LocalDay,
        through finalTrackingDate: LocalDay
    ) -> Set<LocalDay> {
        Set(completions.compactMap { completion in
            guard completion.habitID == habit.id else { return nil }
            let completedDay = completion.completedOn
            guard completedDay >= startDate, completedDay <= finalTrackingDate else {
                return nil
            }
            return completedDay
        })
    }
}
