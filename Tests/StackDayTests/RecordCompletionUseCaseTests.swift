//
//  RecordCompletionUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct RecordCompletionUseCaseTests {
    private let recordedAt = Date(timeIntervalSince1970: 1_172_800)

    @Test("records and persists a completion")
    func recordsAndPersistsCompletion() async throws {
        let referenceDay = try makeReferenceDay()
        let habit = try makeHabit()
        let habits = RecordingHabitRepository(habits: [habit])
        let completions = RecordingCompletionRepository()
        let useCase = makeUseCase(
            habits: habits,
            completions: completions
        )

        try await useCase.execute(
            habitID: habit.id,
            completedOn: referenceDay
        )

        let inserted = await completions.inserted
        let completion = try #require(inserted.first)

        #expect(inserted.count == 1)
        #expect(completion.habitID == habit.id)
        #expect(completion.completedOn == referenceDay)
        #expect(completion.recordedAt == recordedAt)
    }

    @Test("rejects a completion for an unknown habit")
    func rejectsUnknownHabit() async throws {
        let referenceDay = try makeReferenceDay()
        let completions = RecordingCompletionRepository()
        let useCase = makeUseCase(
            habits: RecordingHabitRepository(),
            completions: completions
        )

        await #expect(throws: RecordCompletionError.habitNotFound) {
            try await useCase.execute(
                habitID: Habit.ID(),
                completedOn: referenceDay
            )
        }

        #expect(await completions.inserted.isEmpty)
    }

    @Test("rejects future dates and does not persist them")
    func rejectsFutureDate() async throws {
        let referenceDay = try makeReferenceDay()
        let futureDay = try referenceDay.addingDays(1)
        let habit = try makeHabit()
        let completions = RecordingCompletionRepository()
        let useCase = makeUseCase(
            habits: RecordingHabitRepository(habits: [habit]),
            completions: completions
        )

        await #expect(
            throws: RecordCompletionError.invalidDate(.futureDate)
        ) {
            try await useCase.execute(
                habitID: habit.id,
                completedOn: futureDay
            )
        }

        #expect(await completions.inserted.isEmpty)
    }

    @Test("rejects a duplicate completion")
    func rejectsDuplicateCompletion() async throws {
        let referenceDay = try makeReferenceDay()
        let habit = try makeHabit()
        let existing = Completion(
            habitID: habit.id,
            completedOn: referenceDay,
            recordedAt: recordedAt
        )
        let completions = RecordingCompletionRepository(
            completions: [existing]
        )
        let useCase = makeUseCase(
            habits: RecordingHabitRepository(habits: [habit]),
            completions: completions
        )

        await #expect(throws: RecordCompletionError.alreadyCompleted) {
            try await useCase.execute(
                habitID: habit.id,
                completedOn: referenceDay
            )
        }

        #expect(await completions.inserted.isEmpty)
    }

    @Test("records a completion on an archive date that is within the fixed period")
    func recordsCompletionOnIncludedArchiveDate() async throws {
        let archiveDay = try makeReferenceDay()
        let habit = try Habit(
            name: "Read",
            startedOn: makeStartedOn(),
            archivedOn: archiveDay,
            createdAt: recordedAt
        )
        let completions = RecordingCompletionRepository()
        let useCase = makeUseCase(
            habits: RecordingHabitRepository(habits: [habit]),
            completions: completions
        )

        try await useCase.execute(
            habitID: habit.id,
            completedOn: archiveDay
        )

        let completion = try #require(await completions.inserted.first)
        #expect(completion.completedOn == archiveDay)
    }

    @Test("rejects a completion on an archive date outside the fixed period")
    func rejectsCompletionOnExcludedArchiveDate() async throws {
        let archiveDay = try makeReferenceDay()
        let habit = try Habit(
            name: "Read",
            startedOn: makeStartedOn(),
            archivedOn: try archiveDay.addingDays(-1),
            createdAt: recordedAt
        )
        let completions = RecordingCompletionRepository()
        let useCase = makeUseCase(
            habits: RecordingHabitRepository(habits: [habit]),
            completions: completions
        )

        await #expect(
            throws: RecordCompletionError.invalidDate(.afterHabitArchived)
        ) {
            try await useCase.execute(
                habitID: habit.id,
                completedOn: archiveDay
            )
        }

        #expect(await completions.inserted.isEmpty)
    }

    private func makeStartedOn() throws -> LocalDay {
        try LocalDay(year: 1970, month: 1, day: 12)
    }

    private func makeReferenceDay() throws -> LocalDay {
        try LocalDay(year: 1970, month: 1, day: 14)
    }

    private func makeHabit() throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: makeStartedOn(),
            createdAt: recordedAt
        )
    }

    private func makeUseCase(
        habits: RecordingHabitRepository,
        completions: RecordingCompletionRepository
    ) -> RecordCompletionUseCase {
        RecordCompletionUseCase(
            habitRepository: habits,
            completionRepository: completions,
            clock: FixedClock(now: recordedAt),
            timeZone: .gmt
        )
    }
}
