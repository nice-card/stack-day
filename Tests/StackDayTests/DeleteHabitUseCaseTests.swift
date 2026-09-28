//
//  DeleteHabitUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct DeleteHabitUseCaseTests {
    private let createdAt = Date(timeIntervalSince1970: 1_000_000)

    @Test("deletes a habit and all of its completion records")
    func deletesHabitAndCompletions() async throws {
        let habit = try makeHabit()
        let habits = RecordingHabitRepository(habits: [habit])
        let completions = RecordingCompletionRepository()
        let useCase = DeleteHabitUseCase(
            habitRepository: habits,
            completionRepository: completions
        )

        try await useCase.execute(habitID: habit.id)

        #expect(await completions.deletedAll == [habit.id])
        #expect(await habits.deleted == [habit.id])
    }

    @Test("rejects an unknown habit without deleting anything")
    func rejectsUnknownHabit() async {
        let habits = RecordingHabitRepository()
        let completions = RecordingCompletionRepository()
        let useCase = DeleteHabitUseCase(
            habitRepository: habits,
            completionRepository: completions
        )

        await #expect(throws: DeleteHabitError.habitNotFound) {
            try await useCase.execute(habitID: Habit.ID())
        }

        #expect(await completions.deletedAll.isEmpty)
        #expect(await habits.deleted.isEmpty)
    }

    private func makeStartedOn() throws -> LocalDay {
        try LocalDay(
            year: 1970,
            month: 1,
            day: 12
        )
    }

    private func makeHabit() throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: makeStartedOn(),
            createdAt: createdAt
        )
    }
}
