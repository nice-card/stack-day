//
//  RecordCompletionUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct RecordCompletionUseCaseTests {
    private let startedOn = Date(timeIntervalSince1970: 1_000_000)
    private let referenceDate = Date(timeIntervalSince1970: 1_172_800)

    @Test("records and persists a completion")
    func recordsAndPersistsCompletion() async throws {
        let habit = try makeHabit()
        let habits = RecordingHabitRepository(habits: [habit])
        let completions = RecordingCompletionRepository()
        let useCase = RecordCompletionUseCase(
            habitRepository: habits,
            completionRepository: completions
        ) { self.referenceDate }

        let completion = try await useCase.execute(habitID: habit.id, completedOn: referenceDate)

        #expect(completion.habitID == habit.id)
        #expect(completion.completedOn == referenceDate)
        #expect(completion.recordedAt == referenceDate)
        #expect(await completions.inserted == [completion])
    }

    @Test("rejects a completion for an unknown habit")
    func rejectsUnknownHabit() async {
        let completions = RecordingCompletionRepository()
        let useCase = RecordCompletionUseCase(
            habitRepository: RecordingHabitRepository(),
            completionRepository: completions
        ) { self.referenceDate }

        await #expect(throws: RecordCompletionError.habitNotFound) {
            try await useCase.execute(habitID: Habit.ID(), completedOn: referenceDate)
        }
        #expect(await completions.inserted.isEmpty)
    }

    @Test("rejects future dates and does not persist them")
    func rejectsFutureDate() async throws {
        let habit = try makeHabit()
        let completions = RecordingCompletionRepository()
        let useCase = RecordCompletionUseCase(
            habitRepository: RecordingHabitRepository(habits: [habit]),
            completionRepository: completions
        ) { self.referenceDate }

        await #expect(throws: RecordCompletionError.invalidDate(.futureDate)) {
            try await useCase.execute(
                habitID: habit.id,
                completedOn: referenceDate.addingTimeInterval(86_400)
            )
        }
        #expect(await completions.inserted.isEmpty)
    }

    @Test("rejects a duplicate completion")
    func rejectsDuplicateCompletion() async throws {
        let habit = try makeHabit()
        let existing = Completion(
            habitID: habit.id,
            completedOn: referenceDate,
            recordedAt: referenceDate
        )
        let completions = RecordingCompletionRepository(completions: [existing])
        let useCase = RecordCompletionUseCase(
            habitRepository: RecordingHabitRepository(habits: [habit]),
            completionRepository: completions
        ) { self.referenceDate }

        await #expect(throws: RecordCompletionError.alreadyCompleted) {
            try await useCase.execute(habitID: habit.id, completedOn: referenceDate)
        }
        #expect(await completions.inserted.isEmpty)
    }

    private func makeHabit() throws -> Habit {
        try Habit(name: "Read", startedOn: startedOn, createdAt: startedOn)
    }

}
