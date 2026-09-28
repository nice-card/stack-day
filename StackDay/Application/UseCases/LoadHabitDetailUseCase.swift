//
//  LoadHabitUseCase.swift
//  StackDay
//

import Foundation

struct LoadHabitDetailUseCase {
    private let habitRepository: any HabitRepository

    init(habitRepository: any HabitRepository) {
        self.habitRepository = habitRepository
    }

    func execute(id: Habit.ID) async throws -> Habit {
        guard let habit = try await habitRepository.fetch(id: id) else {
            throw LoadHabitError.habitNotFound
        }
        return habit
    }
}

enum LoadHabitError: Error, Equatable {
    case habitNotFound
}
