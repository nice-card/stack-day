//
//  ArchiveHabitUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct ArchiveHabitUseCaseTests {
    private let archivedAt = Date(timeIntervalSince1970: 1_086_400)

    @Test("includes the archive date in the fixed tracking period when completed")
    func archivesCompletedHabit() async throws {
        let habit = try makeHabit()
        let repository = RecordingHabitRepository(habits: [habit])
        let archiveDay = try LocalDay(date: archivedAt, timeZone: .gmt)
        let completions = RecordingCompletionRepository(completions: [
            Completion(habitID: habit.id, completedOn: archiveDay, recordedAt: archivedAt)
        ])
        let useCase = ArchiveHabitUseCase(
            habitRepository: repository,
            completionRepository: completions,
            clock: FixedClock(now: archivedAt),
            timeZone: .gmt
        )

        let archivedHabit = try await useCase.execute(habitID: habit.id)
        let expectedPeriodEnd = try LocalDay(
            date: archivedAt,
            timeZone: .gmt
        )

        #expect(archivedHabit.trackingPeriods.last?.endedOn == expectedPeriodEnd)
        #expect(archivedHabit.updatedAt == archivedAt)
        #expect(await repository.updated == [archivedHabit])
    }

    @Test("ends tracking before the archive date when incomplete")
    func archivesIncompleteHabit() async throws {
        let habit = try makeHabit()
        let repository = RecordingHabitRepository(habits: [habit])
        let useCase = ArchiveHabitUseCase(
            habitRepository: repository,
            completionRepository: RecordingCompletionRepository(),
            clock: FixedClock(now: archivedAt),
            timeZone: .gmt
        )

        let archivedHabit = try await useCase.execute(habitID: habit.id)
        let archiveDay = try LocalDay(date: archivedAt, timeZone: .gmt)
        let expectedPeriodEnd = try archiveDay.addingDays(-1)

        #expect(archivedHabit.trackingPeriods.last?.endedOn == expectedPeriodEnd)
    }

    @Test("leaves no tracking period when archived on its start date incomplete")
    func archivesStartDateWithoutCompletion() async throws {
        let archiveDay = try LocalDay(date: archivedAt, timeZone: .gmt)
        let habit = try makeHabit(startedOn: archiveDay)
        let useCase = ArchiveHabitUseCase(
            habitRepository: RecordingHabitRepository(habits: [habit]),
            completionRepository: RecordingCompletionRepository(),
            clock: FixedClock(now: archivedAt),
            timeZone: .gmt
        )

        let archivedHabit = try await useCase.execute(habitID: habit.id)
        #expect(archivedHabit.trackingPeriods.isEmpty)
        #expect(archivedHabit.isTracked(on: archiveDay) == false)
    }

    @Test("rejects an unknown habit without updating")
    func rejectsUnknownHabit() async {
        let repository = RecordingHabitRepository()
        let useCase = ArchiveHabitUseCase(
            habitRepository: repository,
            completionRepository: RecordingCompletionRepository(),
            clock: FixedClock(now: archivedAt),
            timeZone: .gmt
        )

        await #expect(throws: ArchiveHabitError.habitNotFound) {
            try await useCase.execute(habitID: Habit.ID())
        }

        #expect(await repository.updated.isEmpty)
    }

    @Test("propagates domain validation and does not update")
    func propagatesDomainValidation() async throws {
        let startedOn = try makeStartedOn()
        let habit = try makeHabit(startedOn: startedOn)
        let repository = RecordingHabitRepository(habits: [habit])

        let beforeStart = try startedOn
            .startDate(in: .gmt)
            .addingTimeInterval(-1)

        let useCase = ArchiveHabitUseCase(
            habitRepository: repository,
            completionRepository: RecordingCompletionRepository(),
            clock: FixedClock(now: beforeStart),
            timeZone: .gmt
        )

        await #expect(throws: HabitError.archiveBeforeCurrentTrackingPeriod) {
            try await useCase.execute(habitID: habit.id)
        }

        #expect(await repository.updated.isEmpty)
    }

    private func makeStartedOn() throws -> LocalDay {
        try LocalDay(
            year: 1970,
            month: 1,
            day: 12
        )
    }

    private func makeHabit(
        startedOn: LocalDay? = nil
    ) throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: startedOn ?? makeStartedOn(),
            createdAt: archivedAt
        )
    }
}
