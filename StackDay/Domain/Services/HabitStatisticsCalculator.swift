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
        let trackingDays = try trackingDays(for: habit, through: referenceDay)
        let trackingDaySet = Set(trackingDays)
        let eligibleTrackingDays = trackingDays.count
        let completedDays = Set<LocalDay>(completions.compactMap { completion in
            guard completion.habitID == habit.id,
                  trackingDaySet.contains(completion.completedOn)
            else { return nil }
            return completion.completedOn
        })
        let totalCompletedDays = completedDays.count
        let completionRate = eligibleTrackingDays == 0
            ? 0
            : Double(totalCompletedDays) / Double(eligibleTrackingDays)
        let streak = calculateStreak(
            trackingDays: trackingDays,
            completedDays: completedDays,
            referenceDay: referenceDay
        )

        return HabitStatistics(
            totalCompletedDays: totalCompletedDays,
            eligibleTrackingDays: eligibleTrackingDays,
            completionRate: completionRate,
            streak: streak
        )
    }

    private func calculateStreak(
        trackingDays: [LocalDay],
        completedDays: Set<LocalDay>,
        referenceDay: LocalDay
    ) -> HabitStreak {
        var longest = 0
        var consecutiveDays = 0
        for date in trackingDays {
            if completedDays.contains(date) {
                consecutiveDays += 1
                longest = max(longest, consecutiveDays)
            } else {
                consecutiveDays = 0
            }
        }

        let currentStreakDays: ArraySlice<LocalDay>
        if trackingDays.last == referenceDay, !completedDays.contains(referenceDay) {
            currentStreakDays = trackingDays.dropLast()
        } else {
            currentStreakDays = trackingDays[...]
        }

        var current = 0
        for day in currentStreakDays.reversed() {
            guard completedDays.contains(day) else { break }
            current += 1
        }

        return HabitStreak(current: current, longest: longest)
    }

    private func trackingDays(for habit: Habit, through referenceDay: LocalDay) throws -> [LocalDay] {
        var days: [LocalDay] = []
        for period in habit.trackingPeriods {
            guard period.startedOn <= referenceDay else { continue }
            let end = min(period.endedOn ?? referenceDay, referenceDay)
            var day = period.startedOn
            while day <= end {
                days.append(day)
                day = try day.addingDays(1)
            }
        }
        return days
    }
}
