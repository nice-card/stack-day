//
//  HabitStatistics.swift
//  StackDay
//

struct HabitStatistics: Equatable {
    let totalCompletedDays: Int
    let eligibleTrackingDays: Int
    let completionRate: Double
    let streak: HabitStreak
}
