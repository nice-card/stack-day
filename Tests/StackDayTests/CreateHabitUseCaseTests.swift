//
//  CreateHabitUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct CreateHabitUseCaseTests {
    private let createdAt = Date(timeIntervalSince1970: 1_000_000)
    private let startedOn = Date(timeIntervalSince1970: 1_086_400)

    @Test("creates and persists a habit")
    func createsAndPersistsHabit() async throws {
        let repository = RecordingHabitRepository()
        let useCase = CreateHabitUseCase(repository: repository) { self.createdAt }

        let habit = try await useCase.execute(name: "  Read  ", startedOn: startedOn)

        #expect(habit.name == "Read")
        #expect(habit.startedOn == startedOn)
        #expect(habit.createdAt == createdAt)
        #expect(await repository.inserted == [habit])
    }

    @Test("does not persist a habit when domain validation fails")
    func doesNotPersistInvalidHabit() async {
        let repository = RecordingHabitRepository()
        let useCase = CreateHabitUseCase(repository: repository) { self.createdAt }

        await #expect(throws: HabitError.emptyName) {
            try await useCase.execute(name: " \n\t ", startedOn: startedOn)
        }

        #expect(await repository.inserted.isEmpty)
    }

    private actor RecordingHabitRepository: HabitRepository {
        private(set) var inserted: [Habit] = []
        
        func fetchAll() async throws -> [Habit] { inserted }
        func fetch(id: Habit.ID) async throws -> Habit? { inserted.first { $0.id == id } }
        func insert(_ habit: Habit) async throws {
            inserted.append(habit)
        }
        func update(_ habit: Habit) async throws {
            if let index = inserted.firstIndex(where: { $0.id == habit.id }) {
                inserted[index] = habit
            }
        }
        func delete(id: Habit.ID) async throws {
            inserted.removeAll { $0.id == id }
        }
    }
}
