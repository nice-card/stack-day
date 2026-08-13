//
//  HabitStatisticsCalculator.swift
//  StackDay
//

import Foundation

struct HabitStatisticsCalculator {
    func calculate(
        habit: Habit,
        completions: [Completion],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> HabitStatistics {
        let startDate = calendar.startOfDay(for: habit.startedOn)
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let finalTrackingDate = min(
            referenceDay,
            habit.archivedOn.map(calendar.startOfDay(for:)) ?? referenceDay
        )
        let eligibleTrackingDays = trackingDayCount(
            from: startDate,
            through: finalTrackingDate,
            calendar: calendar
        )
        let completedDays = completedDays(
            for: habit,
            from: completions,
            from: startDate,
            through: finalTrackingDate,
            calendar: calendar
        )
        let totalCompletedDays = completedDays.count
        let completionRate = eligibleTrackingDays == 0
            ? 0
            : Double(totalCompletedDays) / Double(eligibleTrackingDays)
        let streak = calculateStreak(
            from: startDate,
            through: finalTrackingDate,
            referenceDay: referenceDay,
            completedDays: completedDays,
            calendar: calendar
        )

        return HabitStatistics(
            totalCompletedDays: totalCompletedDays,
            eligibleTrackingDays: eligibleTrackingDays,
            completionRate: completionRate,
            streak: streak
        )
    }

    private func trackingDayCount(
        from startDate: Date,
        through finalTrackingDate: Date,
        calendar: Calendar
    ) -> Int {
        guard startDate <= finalTrackingDate else { return 0 }
        return calendar.dateComponents([.day], from: startDate, to: finalTrackingDate).day! + 1
    }

    private func calculateStreak(
        from startDate: Date,
        through finalTrackingDate: Date,
        referenceDay: Date,
        completedDays: Set<Date>,
        calendar: Calendar
    ) -> HabitStreak {
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
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        var current = 0
        var currentDate = finalTrackingDate
        if finalTrackingDate == referenceDay, !completedDays.contains(referenceDay) {
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        while currentDate >= startDate, completedDays.contains(currentDate) {
            current += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        return HabitStreak(current: current, longest: longest)
    }

    private func completedDays(
        for habit: Habit,
        from completions: [Completion],
        from startDate: Date,
        through finalTrackingDate: Date,
        calendar: Calendar
    ) -> Set<Date> {
        Set(completions.compactMap { completion in
            guard completion.habitID == habit.id else { return nil }
            let completedDay = calendar.startOfDay(for: completion.completedOn)
            guard completedDay >= startDate, completedDay <= finalTrackingDate else {
                return nil
            }
            return completedDay
        })
    }
}
