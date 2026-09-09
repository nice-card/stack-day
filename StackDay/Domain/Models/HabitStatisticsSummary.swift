//
//  HabitStatisticsSummary.swift
//  StackDay
//
//  Created by Kelly Dev on 9/9/26.
//

struct HabitStatisticsSummary: Identifiable {
    let id: Habit.ID
    let name: String
    let isArchived: Bool
    let currentStreak: Int
    let completionRate: Double
}
