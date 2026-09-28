//
//  RecordingHabitRepository.swift
//  StackDay
//
//  Created by Kelly Dev on 8/16/26.
//

@testable import StackDay

actor RecordingHabitRepository: HabitRepository {
    private var stored: [Habit]

    private(set) var inserted: [Habit] = []
    private(set) var updated: [Habit] = []
    private(set) var deleted: [Habit.ID] = []

    init(habits: [Habit] = []) {
        self.stored = habits
    }

    func fetchAll() async throws -> [Habit] {
        stored
    }

    func fetch(id: Habit.ID) async throws -> Habit? {
        stored.first { $0.id == id }
    }

    func insert(_ habit: Habit) async throws {
        inserted.append(habit)
    }

    func update(_ habit: Habit) async throws {
        updated.append(habit)
    }

    func delete(id: Habit.ID) async throws {
        deleted.append(id)
    }
}
