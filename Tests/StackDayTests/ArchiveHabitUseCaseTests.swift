//
//  ArchiveHabitUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct ArchiveHabitUseCaseTests {
    private let archivedAt = Date(timeIntervalSince1970: 1_086_400)

    @Test("archives an existing habit at the injected current time")
    func archivesExistingHabit() async throws {
        let habit = try makeHabit()
        let repository = RecordingHabitRepository(habits: [habit])
        let useCase = ArchiveHabitUseCase(
            repository: repository,
            clock: FixedClock(now: archivedAt),
            timeZone: .gmt
        )

        let archivedHabit = try await useCase.execute(habitID: habit.id)
        let expectedArchivedOn = try LocalDay(
            date: archivedAt,
            timeZone: .gmt
        )

        #expect(archivedHabit.archivedOn == expectedArchivedOn)
        #expect(archivedHabit.updatedAt == archivedAt)
        #expect(await repository.updated == [archivedHabit])
    }

    @Test("rejects an unknown habit without updating")
    func rejectsUnknownHabit() async {
        let repository = RecordingHabitRepository()
        let useCase = ArchiveHabitUseCase(
            repository: repository,
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
            repository: repository,
            clock: FixedClock(now: beforeStart),
            timeZone: .gmt
        )

        await #expect(throws: HabitError.archiveBeforeStart) {
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
