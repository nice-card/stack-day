//
//  CreateHabitUseCase.swift
//  StackDay
//

import Foundation

struct CreateHabitUseCase {
    private let repository: any HabitRepository
    private let now: () -> Date

    init(repository: any HabitRepository, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    func execute(name: String, startedOn: Date) async throws -> Habit {
        let habit = try Habit(
            name: name,
            startedOn: startedOn,
            createdAt: now()
        )

        try await repository.insert(habit)
        return habit
    }
}
