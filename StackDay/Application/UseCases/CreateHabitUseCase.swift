//
//  CreateHabitUseCase.swift
//  StackDay
//

import Foundation

struct CreateHabitUseCase {
    private let repository: any HabitRepository
    private let clock: any Clock

    init(repository: any HabitRepository, clock: any Clock) {
        self.repository = repository
        self.clock = clock
    }

    func execute(name: String, startedOn: LocalDay) async throws {
        let habit = try Habit(
            name: name,
            startedOn: startedOn,
            createdAt: clock.now
        )

        try await repository.insert(habit)
    }
}
