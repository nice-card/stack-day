//
//  RecordingCompletionRepository.swift
//  StackDay
//
//  Created by Kelly Dev on 8/16/26.
//

import Foundation
@testable import StackDay

actor RecordingCompletionRepository: CompletionRepository {
    private var stored: [Completion]

    private(set) var inserted: [Completion] = []
    private(set) var deleted: [Completion.ID] = []
    private(set) var deletedAll: [Habit.ID] = []

    init(completions: [Completion] = []) {
        self.stored = completions
    }

    func fetchAll(for habitID: Habit.ID) async throws -> [Completion] {
        stored.filter { $0.habitID == habitID }
    }

    func fetch(
        habitID: Habit.ID,
        completedOn date: LocalDay
    ) async throws -> Completion? {
        stored.first {
            $0.habitID == habitID &&
            $0.completedOn == date
        }
    }

    func insert(_ completion: Completion) async throws {
        inserted.append(completion)
    }

    func delete(id completionID: Completion.ID) async throws {
        deleted.append(completionID)
    }

    func deleteAll(for habitID: Habit.ID) async throws {
        deletedAll.append(habitID)
    }
}
