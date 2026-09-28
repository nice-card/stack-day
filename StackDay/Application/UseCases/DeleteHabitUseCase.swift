//
//  DeleteHabitUseCase.swift
//  StackDay
//

import Foundation

struct DeleteHabitUseCase {
    private let habitRepository: any HabitRepository
    private let completionRepository: any CompletionRepository

    init(
        habitRepository: any HabitRepository,
        completionRepository: any CompletionRepository
    ) {
        self.habitRepository = habitRepository
        self.completionRepository = completionRepository
    }

    func execute(habitID: Habit.ID) async throws {
        guard try await habitRepository.fetch(id: habitID) != nil else {
            throw DeleteHabitError.habitNotFound
        }

        try await completionRepository.deleteAll(for: habitID)
        try await habitRepository.delete(id: habitID)
    }
}

enum DeleteHabitError: Error, Equatable {
    case habitNotFound
}
