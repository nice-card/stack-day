//
//  LoadHabitUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct LoadHabitUseCaseTests {
    @Test("loads a habit by ID")
    func loadsHabitByID() async throws {
        let startedOn = try LocalDay(year: 2026, month: 8, day: 19)
        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: Date(timeIntervalSince1970: 1_000_000)
        )
        let repository = RecordingHabitRepository(habits: [habit])
        let useCase = LoadHabitDetailUseCase(habitRepository: repository)

        let loadedHabit = try await useCase.execute(id: habit.id)

        #expect(loadedHabit == habit)
    }

    @Test("rejects an unknown habit ID")
    func rejectsUnknownHabitID() async {
        let useCase = LoadHabitDetailUseCase(habitRepository: RecordingHabitRepository())

        await #expect(throws: LoadHabitError.habitNotFound) {
            try await useCase.execute(id: Habit.ID())
        }
    }
}
