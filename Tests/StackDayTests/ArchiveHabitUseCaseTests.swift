//
//  ArchiveHabitUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct ArchiveHabitUseCaseTests {
    private let startedOn = Date(timeIntervalSince1970: 1_000_000)
    private let archivedOn = Date(timeIntervalSince1970: 1_086_400)

    @Test("archives an existing habit at the injected current time")
    func archivesExistingHabit() async throws {
        let habit = try makeHabit()
        let repository = RecordingHabitRepository(habits: [habit])
        let useCase = ArchiveHabitUseCase(repository: repository) { self.archivedOn }

        let archivedHabit = try await useCase.execute(habitID: habit.id)

        #expect(archivedHabit.archivedOn == archivedOn)
        #expect(archivedHabit.updatedAt == archivedOn)
        #expect(await repository.updated == [archivedHabit])
    }

    @Test("rejects an unknown habit without updating")
    func rejectsUnknownHabit() async {
        let repository = RecordingHabitRepository()
        let useCase = ArchiveHabitUseCase(repository: repository) { self.archivedOn }

        await #expect(throws: ArchiveHabitError.habitNotFound) {
            try await useCase.execute(habitID: Habit.ID())
        }

        #expect(await repository.updated.isEmpty)
    }

    @Test("propagates domain validation and does not update")
    func propagatesDomainValidation() async throws {
        let habit = try makeHabit()
        let repository = RecordingHabitRepository(habits: [habit])
        let useCase = ArchiveHabitUseCase(repository: repository) { startedOn.addingTimeInterval(-1) }

        await #expect(throws: HabitError.archiveBeforeStart) {
            try await useCase.execute(habitID: habit.id)
        }

        #expect(await repository.updated.isEmpty)
    }

    private func makeHabit() throws -> Habit {
        try Habit(name: "Read", startedOn: startedOn, createdAt: startedOn)
    }

}
