//
//  CompletionRepository.swift
//  StackDay
//

import Foundation

protocol CompletionRepository {
    func fetchAll(for habitID: Habit.ID) async throws -> [Completion]
    func fetch(habitID: Habit.ID, completedOn date: LocalDay) async throws -> Completion?
    func insert(_ completion: Completion) async throws
    func delete(id: Completion.ID) async throws
    func deleteAll(for habitID: Habit.ID) async throws
}
