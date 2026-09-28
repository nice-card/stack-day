//
//  HabitRepository.swift
//  StackDay
//

import Foundation

protocol HabitRepository {
    func fetchAll() async throws -> [Habit]
    func fetch(id: Habit.ID) async throws -> Habit?
    func insert(_ habit: Habit) async throws
    func update(_ habit: Habit) async throws
    func delete(id: Habit.ID) async throws
}
