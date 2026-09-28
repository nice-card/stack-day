//
//  RecordCompletionUseCase.swift
//  StackDay
//

import Foundation

struct RecordCompletionUseCase {
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

    func execute(habitID: Habit.ID, completedOn: Date) async throws -> Completion {
        guard let habit = try await habitRepository.fetch(id: habitID) else {
            throw RecordCompletionError.habitNotFound
        }

        let referenceDate = now()
        do {
            try habit.validateDate(completedOn, referenceDate: referenceDate)
        } catch let error as HabitDateError {
            throw RecordCompletionError.invalidDate(error)
        }

        if try await completionRepository.fetch(habitID: habitID, completedOn: completedOn) != nil {
            throw RecordCompletionError.alreadyCompleted
        }

        let completion = Completion(
            habitID: habitID,
            completedOn: completedOn,
            recordedAt: referenceDate
        )
        try await completionRepository.insert(completion)
        return completion
    }
}

enum RecordCompletionError: Error, Equatable {
    case habitNotFound
    case invalidDate(HabitDateError)
    case alreadyCompleted
}
