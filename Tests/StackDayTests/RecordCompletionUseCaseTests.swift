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

    private actor RecordingHabitRepository: HabitRepository {
        var habits: [Habit]
        init(habits: [Habit] = []) { self.habits = habits }
        func fetchAll() async throws -> [Habit] { habits }
        func fetch(id: Habit.ID) async throws -> Habit? { habits.first { $0.id == id } }
        func insert(_ habit: Habit) async throws { habits.append(habit) }
        func update(_ habit: Habit) async throws { habits = habits.map { $0.id == habit.id ? habit : $0 } }
        func delete(id: Habit.ID) async throws { habits.removeAll { $0.id == id } }
    }

    private actor RecordingCompletionRepository: CompletionRepository {
        private var stored: [Completion]
        private(set) var inserted: [Completion] = []

        init(completions: [Completion] = []) { stored = completions }

        func fetchAll(for habitID: Habit.ID) async throws -> [Completion] {
            stored.filter { $0.habitID == habitID }
        }
        func fetch(habitID: Habit.ID, completedOn date: Date) async throws -> Completion? {
            stored.first { $0.habitID == habitID && $0.completedOn == date }
        }
        func insert(_ completion: Completion) async throws {
            inserted.append(completion)
        }
        func delete(habitID: Habit.ID, completedOn date: Date) async throws {
            stored.removeAll { $0.habitID == habitID && $0.completedOn == date }
        }
        func deleteAll(for habitID: Habit.ID) async throws {
            stored.removeAll { $0.habitID == habitID }
        }
    }
}
