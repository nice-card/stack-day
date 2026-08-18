//
//  CreateHabitUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct CreateHabitUseCaseTests {
    private let createdAt = Date(timeIntervalSince1970: 1_000_000)

    @Test("creates and persists a habit")
    func createsAndPersistsHabit() async throws {
        let startedOn = try makeStartedOn()
        let repository = RecordingHabitRepository()
        let useCase = CreateHabitUseCase(
            repository: repository,
            clock: FixedClock(now: createdAt)
        )

        let habit = try await useCase.execute(
            name: "  Read  ",
            startedOn: startedOn
        )

        #expect(habit.name == "Read")
        #expect(habit.startedOn == startedOn)
        #expect(habit.createdAt == createdAt)
        #expect(await repository.inserted == [habit])
    }

    @Test("does not persist a habit when domain validation fails")
    func doesNotPersistInvalidHabit() async throws {
        let startedOn = try makeStartedOn()
        let repository = RecordingHabitRepository()
        let useCase = CreateHabitUseCase(
            repository: repository,
            clock: FixedClock(now: createdAt)
        )

        await #expect(throws: HabitError.emptyName) {
            try await useCase.execute(
                name: " \n\t ",
                startedOn: startedOn
            )
        }

        #expect(await repository.inserted.isEmpty)
    }

    private func makeStartedOn() throws -> LocalDay {
        try LocalDay(
            year: 1970,
            month: 1,
            day: 13
        )
    }
}
