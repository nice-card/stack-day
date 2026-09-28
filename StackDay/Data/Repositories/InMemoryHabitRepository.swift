//
//  InMemoryHabitRepository.swift
//  StackDay
//

import Foundation

actor InMemoryHabitRepository: HabitRepository {
    private var habits: [Habit.ID: Habit] = [:]

    func fetchAll() async throws -> [Habit] {
        Array(habits.values)
    }
    func fetch(id: Habit.ID) async throws -> Habit? {
        habits[id]
    }
    func insert(_ habit: Habit) async throws {
        guard habits[habit.id] == nil else {
            throw HabitRepositoryError.alreadyExists
        }
        habits[habit.id] = habit
    }
    func update(_ habit: Habit) async throws {
        guard habits[habit.id] != nil else {
            throw HabitRepositoryError.notFound
        }
        habits[habit.id] = habit
    }
    func delete(id: Habit.ID) async throws {
        guard habits.removeValue(forKey: id) != nil else {
            throw HabitRepositoryError.notFound
        }
    }
}
