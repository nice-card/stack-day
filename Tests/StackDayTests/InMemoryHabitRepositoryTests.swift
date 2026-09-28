//
//  InMemoryHabitRepositoryTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct InMemoryHabitRepositoryTests {
    private let createdAt = Date(timeIntervalSince1970: 1_000_000)

    @Test("inserts and fetches a habit by id")
    func insertsAndFetchesHabit() async throws {
        let repository = InMemoryHabitRepository()
        let habit = try makeHabit(name: "Read")

        try await repository.insert(habit)

        #expect(
            try await repository.fetch(id: habit.id) == habit
        )
    }

    @Test("rejects inserting a habit with an existing id")
    func rejectsDuplicateInsert() async throws {
        let habit = try makeHabit(name: "Read")
        let repository = InMemoryHabitRepository()

        try await repository.insert(habit)

        await #expect(throws: HabitRepositoryError.alreadyExists) {
            try await repository.insert(habit)
        }
    }

    @Test("fetches all inserted habits")
    func fetchesAllHabits() async throws {
        let repository = InMemoryHabitRepository()
        let first = try makeHabit(name: "Read")
        let second = try makeHabit(name: "Walk")

        try await repository.insert(first)
        try await repository.insert(second)

        let fetched = try await repository.fetchAll()

        #expect(
            Set(fetched.map(\.id)) == Set([first.id, second.id])
        )
    }

    @Test("updates the stored habit")
    func updatesHabit() async throws {
        let startedOn = try makeStartedOn()
        let archiveDay = try startedOn.addingDays(1)
        let updatedAt = createdAt.addingTimeInterval(86_400)

        let habit = try makeHabit(
            name: "Read",
            startedOn: startedOn
        )
        var archivedHabit = habit
        let repository = InMemoryHabitRepository()

        try await repository.insert(habit)

        try archivedHabit.archive(
            on: archiveDay,
            updatedAt: updatedAt
        )

        try await repository.update(archivedHabit)

        #expect(
            try await repository.fetch(id: habit.id) == archivedHabit
        )
    }

    @Test("rejects updating a missing habit")
    func rejectsUpdateForMissingHabit() async throws {
        let habit = try makeHabit(name: "Read")
        let repository = InMemoryHabitRepository()

        await #expect(throws: HabitRepositoryError.notFound) {
            try await repository.update(habit)
        }
    }

    @Test("deletes a habit")
    func deletesHabit() async throws {
        let habit = try makeHabit(name: "Read")
        let repository = InMemoryHabitRepository()

        try await repository.insert(habit)
        try await repository.delete(id: habit.id)

        #expect(
            try await repository.fetch(id: habit.id) == nil
        )
        #expect(
            try await repository.fetchAll().isEmpty
        )
    }

    @Test("rejects deleting a missing habit")
    func rejectsDeleteForMissingHabit() async {
        let repository = InMemoryHabitRepository()

        await #expect(throws: HabitRepositoryError.notFound) {
            try await repository.delete(id: Habit.ID())
        }
    }

    private func makeStartedOn() throws -> LocalDay {
        try LocalDay(
            year: 1970,
            month: 1,
            day: 12
        )
    }

    private func makeHabit(
        name: String,
        startedOn: LocalDay? = nil
    ) throws -> Habit {
        try Habit(
            name: name,
            startedOn: startedOn ?? makeStartedOn(),
            createdAt: createdAt
        )
    }
}
