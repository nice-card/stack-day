//
//  CancelCompletionUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct CancelCompletionUseCaseTests {
    private let recordedAt = Date(timeIntervalSince1970: 1_172_800)

    @Test("deletes an existing completion")
    func deletesExistingCompletion() async throws {
        let referenceDay = try makeReferenceDay()
        let habit = try makeHabit()
        let completion = Completion(
            habitID: habit.id,
            completedOn: referenceDay,
            recordedAt: recordedAt
        )
        let completions = RecordingCompletionRepository(
            completions: [completion]
        )
        let useCase = makeUseCase(
            habit: habit,
            completions: completions
        )

        try await useCase.execute(
            habitID: habit.id,
            completedOn: referenceDay
        )

        #expect(await completions.deleted == [completion.id])
    }

    @Test("rejects an unknown habit")
    func rejectsUnknownHabit() async throws {
        let referenceDay = try makeReferenceDay()
        let completions = RecordingCompletionRepository()
        let useCase = makeUseCase(completions: completions)

        await #expect(throws: CancelCompletionError.habitNotFound) {
            try await useCase.execute(
                habitID: Habit.ID(),
                completedOn: referenceDay
            )
        }

        #expect(await completions.deleted.isEmpty)
    }

    @Test("rejects a missing completion")
    func rejectsMissingCompletion() async throws {
        let referenceDay = try makeReferenceDay()
        let habit = try makeHabit()
        let completions = RecordingCompletionRepository()
        let useCase = makeUseCase(
            habit: habit,
            completions: completions
        )

        await #expect(throws: CancelCompletionError.notCompleted) {
            try await useCase.execute(
                habitID: habit.id,
                completedOn: referenceDay
            )
        }

        #expect(await completions.deleted.isEmpty)
    }

    @Test("rejects a future date without deleting")
    func rejectsFutureDate() async throws {
        let referenceDay = try makeReferenceDay()
        let futureDay = try referenceDay.addingDays(1)
        let habit = try makeHabit()
        let completion = Completion(
            habitID: habit.id,
            completedOn: futureDay,
            recordedAt: recordedAt
        )
        let completions = RecordingCompletionRepository(
            completions: [completion]
        )
        let useCase = makeUseCase(
            habit: habit,
            completions: completions
        )

        await #expect(
            throws: CancelCompletionError.invalidDate(.futureDate)
        ) {
            try await useCase.execute(
                habitID: habit.id,
                completedOn: futureDay
            )
        }

        #expect(await completions.deleted.isEmpty)
    }

    @Test("cancels a completion on an archive date")
    func cancelsCompletionOnArchiveDate() async throws {
        let archiveDay = try makeReferenceDay()
        let habit = try Habit(
            name: "Read",
            startedOn: makeStartedOn(),
            trackingPeriods: [
                try TrackingPeriod(startedOn: makeStartedOn(), endedOn: archiveDay)
            ],
            createdAt: recordedAt
        )
        let completion = Completion(
            habitID: habit.id,
            completedOn: archiveDay,
            recordedAt: recordedAt
        )
        let completions = RecordingCompletionRepository(
            completions: [completion]
        )
        let useCase = makeUseCase(
            habit: habit,
            completions: completions
        )

        try await useCase.execute(
            habitID: habit.id,
            completedOn: archiveDay
        )

        #expect(await completions.deleted == [completion.id])
    }

    private func makeStartedOn() throws -> LocalDay {
        try LocalDay(
            year: 1970,
            month: 1,
            day: 12
        )
    }

    private func makeReferenceDay() throws -> LocalDay {
        try LocalDay(
            year: 1970,
            month: 1,
            day: 14
        )
    }

    private func makeHabit() throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: makeStartedOn(),
            createdAt: recordedAt
        )
    }

    private func makeUseCase(
        habit: Habit? = nil,
        completions: RecordingCompletionRepository
    ) -> CancelCompletionUseCase {
        CancelCompletionUseCase(
            habitRepository: RecordingHabitRepository(
                habits: habit.map { [$0] } ?? []
            ),
            completionRepository: completions,
            clock: FixedClock(now: recordedAt),
            timeZone: .gmt
        )
    }
}
