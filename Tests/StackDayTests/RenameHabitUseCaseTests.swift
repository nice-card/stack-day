//
//  RenameHabitUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct RenameHabitUseCaseTests {
    private let createdAt = Date(timeIntervalSince1970: 1_000_000)
    private let renamedAt = Date(timeIntervalSince1970: 1_100_000)

    @Test("renames a habit, trims its name, and persists the update")
    func renamesAndPersistsHabit() async throws {
        let habit = try makeHabit()
        let repository = RecordingHabitRepository(habits: [habit])
        let useCase = RenameHabitUseCase(
            habitRepository: repository,
            clock: FixedClock(now: renamedAt)
        )

        let renamedHabit = try await useCase.execute(
            habitID: habit.id,
            name: "  Exercise  "
        )

        #expect(renamedHabit.name == "Exercise")
        #expect(renamedHabit.updatedAt == renamedAt)
        #expect(await repository.updated == [renamedHabit])
    }

    @Test("rejects an empty name without persisting an update")
    func rejectsEmptyName() async throws {
        let habit = try makeHabit()
        let repository = RecordingHabitRepository(habits: [habit])
        let useCase = RenameHabitUseCase(
            habitRepository: repository,
            clock: FixedClock(now: renamedAt)
        )

        await #expect(throws: HabitError.emptyName) {
            try await useCase.execute(habitID: habit.id, name: " \n\t ")
        }

        #expect(await repository.updated.isEmpty)
    }

    @Test("rejects an unknown habit without persisting an update")
    func rejectsUnknownHabit() async {
        let repository = RecordingHabitRepository()
        let useCase = RenameHabitUseCase(
            habitRepository: repository,
            clock: FixedClock(now: renamedAt)
        )

        await #expect(throws: RenameHabitError.habitNotFound) {
            try await useCase.execute(habitID: Habit.ID(), name: "Exercise")
        }

        #expect(await repository.updated.isEmpty)
    }

    private func makeHabit() throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: LocalDay(year: 1970, month: 1, day: 12),
            createdAt: createdAt
        )
    }
}
