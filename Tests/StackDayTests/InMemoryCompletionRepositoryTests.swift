//
//  InMemoryCompletionRepositoryTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct InMemoryCompletionRepositoryTests {
    private let habitID = Habit.ID()
    private let otherHabitID = Habit.ID()
    private let recordedAt = Date(timeIntervalSince1970: 1_000_000)

    @Test("inserts and fetches a completion by habit and day")
    func insertsAndFetchesCompletion() async throws {
        let completionDay = try makeCompletionDay()
        let repository = InMemoryCompletionRepository()
        let completion = makeCompletion(on: completionDay)

        try await repository.insert(completion)

        #expect(
            try await repository.fetch(
                habitID: habitID,
                completedOn: completionDay
            ) == completion
        )
    }

    @Test("fetches all completions for a habit")
    func fetchesAllCompletions() async throws {
        let completionDay = try makeCompletionDay()
        let nextDay = try completionDay.addingDays(1)

        let first = makeCompletion(on: completionDay)
        let second = Completion(
            habitID: habitID,
            completedOn: nextDay,
            recordedAt: recordedAt
        )
        let other = Completion(
            habitID: otherHabitID,
            completedOn: completionDay,
            recordedAt: recordedAt
        )
        let repository = InMemoryCompletionRepository()

        try await repository.insert(first)
        try await repository.insert(second)
        try await repository.insert(other)

        let fetched = try await repository.fetchAll(for: habitID)

        #expect(Set(fetched.map(\.id)) == Set([first.id, second.id]))
    }

    @Test("rejects a duplicate completion id")
    func rejectsDuplicateID() async throws {
        let completionDay = try makeCompletionDay()
        let completion = makeCompletion(on: completionDay)
        let repository = InMemoryCompletionRepository()

        try await repository.insert(completion)

        await #expect(throws: CompletionRepositoryError.alreadyExists) {
            try await repository.insert(completion)
        }
    }

    @Test("rejects a second completion for the same habit and day")
    func rejectsDuplicateDay() async throws {
        let completionDay = try makeCompletionDay()
        let completion = makeCompletion(on: completionDay)
        let duplicate = Completion(
            habitID: habitID,
            completedOn: completionDay,
            recordedAt: recordedAt.addingTimeInterval(1)
        )
        let repository = InMemoryCompletionRepository()

        try await repository.insert(completion)

        await #expect(throws: CompletionRepositoryError.alreadyExists) {
            try await repository.insert(duplicate)
        }
    }

    @Test("deletes a completion")
    func deletesCompletion() async throws {
        let completionDay = try makeCompletionDay()
        let completion = makeCompletion(on: completionDay)
        let repository = InMemoryCompletionRepository()

        try await repository.insert(completion)
        try await repository.delete(id: completion.id)

        #expect(
            try await repository.fetch(
                habitID: habitID,
                completedOn: completionDay
            ) == nil
        )
    }

    @Test("rejects deleting an unknown completion")
    func rejectsUnknownCompletion() async {
        let repository = InMemoryCompletionRepository()

        await #expect(throws: CompletionRepositoryError.notFound) {
            try await repository.delete(id: Completion.ID())
        }
    }

    @Test("deletes all completions for a habit")
    func deletesAllForHabit() async throws {
        let completionDay = try makeCompletionDay()
        let nextDay = try completionDay.addingDays(1)

        let first = makeCompletion(on: completionDay)
        let second = Completion(
            habitID: habitID,
            completedOn: nextDay,
            recordedAt: recordedAt
        )
        let other = Completion(
            habitID: otherHabitID,
            completedOn: completionDay,
            recordedAt: recordedAt
        )
        let repository = InMemoryCompletionRepository()

        try await repository.insert(first)
        try await repository.insert(second)
        try await repository.insert(other)

        try await repository.deleteAll(for: habitID)

        #expect(try await repository.fetchAll(for: habitID).isEmpty)
        #expect(try await repository.fetchAll(for: otherHabitID).count == 1)
    }

    @Test("deleting all for a habit without completions succeeds")
    func deleteAllWithoutCompletionsSucceeds() async throws {
        let repository = InMemoryCompletionRepository()

        try await repository.deleteAll(for: habitID)

        #expect(try await repository.fetchAll(for: habitID).isEmpty)
    }

    private func makeCompletionDay() throws -> LocalDay {
        try LocalDay(
            year: 1970,
            month: 1,
            day: 12
        )
    }

    private func makeCompletion(
        on day: LocalDay
    ) -> Completion {
        Completion(
            habitID: habitID,
            completedOn: day,
            recordedAt: recordedAt
        )
    }
}
