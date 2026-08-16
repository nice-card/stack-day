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
        let completions = RecordingCompletionRepository(stored: [completion])
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
        let completions = RecordingCompletionRepository(stored: [
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
            habitRepository: RecordingHabitRepository(habit: habit),
            completionRepository: completions
        ) { self.referenceDate }
    }

    private actor RecordingHabitRepository: HabitRepository {
        private let habit: Habit?
        init(habit: Habit? = nil) { self.habit = habit }
        func fetchAll() async throws -> [Habit] { habit.map { [$0] } ?? [] }
        func fetch(id: Habit.ID) async throws -> Habit? { habit?.id == id ? habit : nil }
        func insert(_ habit: Habit) async throws {}
        func update(_ habit: Habit) async throws {}
        func delete(id: Habit.ID) async throws {}
    }

    private actor RecordingCompletionRepository: CompletionRepository {
        private var stored: [Completion]
        private(set) var deleted: [Completion.ID] = []

        init(stored: [Completion] = []) {
            self.stored = stored
        }
        func fetchAll(for habitID: Habit.ID) async throws -> [Completion] {
            stored.filter { $0.habitID == habitID }
        }
        func fetch(
            habitID: Habit.ID,
            completedOn date: Date
        ) async throws -> Completion? {
            stored.first {
                $0.habitID == habitID &&
                $0.completedOn == date
            }
        }
        func insert(_ completion: Completion) async throws {
            stored.append(completion)
        }
        func delete(id completionID: Completion.ID) async throws {
            deleted.append(completionID)
            stored.removeAll { $0.id == completionID }
        }
        func deleteAll(for habitID: Habit.ID) async throws {
            stored.removeAll { $0.habitID == habitID }
        }
    }
}
