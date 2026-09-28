//
//  CancelCompletionUseCase.swift
//  StackDay
//

import Foundation

struct CancelCompletionUseCase {
    private let habitRepository: any HabitRepository
    private let completionRepository: any CompletionRepository
    private let clock: any Clock
    private let timeZone: TimeZone

    init(
        habitRepository: any HabitRepository,
        completionRepository: any CompletionRepository,
        clock: any Clock,
        timeZone: TimeZone
    ) {
        self.habitRepository = habitRepository
        self.completionRepository = completionRepository
        self.clock = clock
        self.timeZone = timeZone
    }

    func execute(habitID: Habit.ID, completedOn: LocalDay) async throws {
        guard let habit = try await habitRepository.fetch(id: habitID) else {
            throw CancelCompletionError.habitNotFound
        }

        let now = clock.now
        let referenceDay = try LocalDay(date: now, timeZone: timeZone)

        do {
            try habit.validateRecordableDate(
                completedOn,
                referenceDay: referenceDay
            )
        } catch let error as HabitError {
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
    case invalidDate(HabitError)
    case notCompleted
}
