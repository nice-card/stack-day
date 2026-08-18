//
//  RecordCompletionUseCase.swift
//  StackDay
//

import Foundation

struct RecordCompletionUseCase {
    private let habitRepository: any HabitRepository
    private let completionRepository: any CompletionRepository
    private let clock: any Clock
    private let timeZone: TimeZone

    init(
        habitRepository: any HabitRepository,
        completionRepository: any CompletionRepository,
        clock: any Clock = SystemClock(),
        timeZone: TimeZone = .current
    ) {
        self.habitRepository = habitRepository
        self.completionRepository = completionRepository
        self.clock = clock
        self.timeZone = timeZone
    }

    func execute(habitID: Habit.ID, completedOn: LocalDay) async throws -> Completion {
        guard let habit = try await habitRepository.fetch(id: habitID) else {
            throw RecordCompletionError.habitNotFound
        }

        let now = clock.now
        let referenceDay = try LocalDay(
            date: now,
            timeZone: timeZone
        )

        do {
            try habit.validateDate(
                completedOn,
                referenceDay: referenceDay
            )
        } catch let error as HabitDateError {
            throw RecordCompletionError.invalidDate(error)
        }

        if try await completionRepository.fetch(
            habitID: habitID,
            completedOn: completedOn
        ) != nil {
            throw RecordCompletionError.alreadyCompleted
        }

        let completion = Completion(
            habitID: habitID,
            completedOn: completedOn,
            recordedAt: now
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
