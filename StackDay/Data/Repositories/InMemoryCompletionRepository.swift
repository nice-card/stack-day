//
//  InMemoryCompletionRepository.swift
//  StackDay
//

import Foundation

actor InMemoryCompletionRepository: CompletionRepository {
    private var completions: [Completion.ID: Completion] = [:]

    func fetchAll(for habitID: Habit.ID) async throws -> [Completion] {
        completions.values.filter { $0.habitID == habitID }
    }
    func fetch(habitID: Habit.ID, completedOn day: LocalDay) async throws -> Completion? {
        completions.values.first {
            $0.habitID == habitID && $0.completedOn == day
        }
    }
    func insert(_ completion: Completion) async throws {
        guard completions[completion.id] == nil else {
            throw CompletionRepositoryError.alreadyExists
        }
        guard !completions.values.contains(where: {
            $0.habitID == completion.habitID &&
            $0.completedOn == completion.completedOn
        }) else {
            throw CompletionRepositoryError.alreadyExists
        }
        completions[completion.id] = completion
    }
    func delete(id completionID: Completion.ID) async throws {
        guard completions.removeValue(forKey: completionID) != nil else {
            throw CompletionRepositoryError.notFound
        }
    }
    func deleteAll(for habitID: Habit.ID) async throws {
        completions = completions.filter { $0.value.habitID != habitID }
    }
}
