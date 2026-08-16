//
//  CancelCompletionUseCase.swift
//  StackDay
//

import Foundation

struct CancelCompletionUseCase {
    private let habitRepository: any HabitRepository
    private let completionRepository: any CompletionRepository
    private let now: () -> Date

    init(
        habitRepository: any HabitRepository,
        completionRepository: any CompletionRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.habitRepository = habitRepository
        self.completionRepository = completionRepository
        self.now = now
    }

    func execute(habitID: Habit.ID, completedOn: Date) async throws {
        guard let habit = try await habitRepository.fetch(id: habitID) else {
            throw CancelCompletionError.habitNotFound
        }
        
        let referenceDate = now()
        do {
            try habit.validateDate(completedOn, referenceDate: referenceDate)
        } catch let error as HabitDateError {
            throw CancelCompletionError.invalidDate(error)
        }

        guard let completion = try await completionRepository.fetch(
            habitID: habitID,
            completedOn: completedOn
        ) else {
            throw CancelCompletionError.notCompleted
        }

        try await completionRepository.delete(id: completion.id)
    }
}

enum CancelCompletionError: Error, Equatable {
    case habitNotFound
    case invalidDate(HabitDateError)
    case notCompleted
}
