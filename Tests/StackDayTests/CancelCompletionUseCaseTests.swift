//
//  CancelCompletionUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct CancelCompletionUseCaseTests {
    private let startedOn = Date(timeIntervalSince1970: 1_000_000)
    private let referenceDate = Date(timeIntervalSince1970: 1_172_800)

    @Test("deletes an existing completion")
    func deletesExistingCompletion() async throws {
        let habit = try makeHabit()
        let completion = Completion(
            habitID: habit.id,
            completedOn: referenceDate,
            recordedAt: referenceDate
        )
        let completions = RecordingCompletionRepository(completions: [completion])
        let useCase = makeUseCase(habit: habit, completions: completions)

        try await useCase.execute(habitID: habit.id, completedOn: referenceDate)

        #expect(await completions.deleted == [completion.id])
    }

    @Test("rejects an unknown habit")
    func rejectsUnknownHabit() async {
        let completions = RecordingCompletionRepository()
        let useCase = makeUseCase(completions: completions)

        await #expect(throws: CancelCompletionError.habitNotFound) {
            try await useCase.execute(habitID: Habit.ID(), completedOn: referenceDate)
        }

        #expect(await completions.deleted.isEmpty)
    }

    @Test("rejects a missing completion")
    func rejectsMissingCompletion() async throws {
        let habit = try makeHabit()
        let completions = RecordingCompletionRepository()
        let useCase = makeUseCase(habit: habit, completions: completions)

        await #expect(throws: CancelCompletionError.notCompleted) {
            try await useCase.execute(
                habitID: habit.id,
                completedOn: referenceDate
            )
        }

        #expect(await completions.deleted.isEmpty)
    }

    @Test("rejects a future date without deleting")
    func rejectsFutureDate() async throws {
        let habit = try makeHabit()
        let completionDate = referenceDate.addingTimeInterval(86_400)
        let completions = RecordingCompletionRepository(completions: [
            Completion(habitID: habit.id, completedOn: completionDate, recordedAt: referenceDate)
        ])
        let useCase = makeUseCase(habit: habit, completions: completions)

        await #expect(throws: CancelCompletionError.invalidDate(.futureDate)) {
            try await useCase.execute(habitID: habit.id, completedOn: completionDate)
        }

        #expect(await completions.deleted.isEmpty)
    }

    private func makeHabit() throws -> Habit {
        try Habit(name: "Read", startedOn: startedOn, createdAt: startedOn)
    }

    private func makeUseCase(
        habit: Habit? = nil,
        completions: RecordingCompletionRepository
    ) -> CancelCompletionUseCase {
        CancelCompletionUseCase(
            habitRepository: RecordingHabitRepository(habits: habit.map { [$0] } ?? []),
            completionRepository: completions
        ) { self.referenceDate }
    }

}
