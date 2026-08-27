//
//  LoadMonthlyEntriesUseCase.swift
//  StackDay
//

import Foundation

struct LoadMonthlyEntriesUseCase {
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

    func execute(
        habitID: Habit.ID,
        year: Int,
        month: Int
    ) async throws -> [HabitEntry] {
        guard let habit = try await habitRepository.fetch(id: habitID) else {
            throw LoadMonthlyEntriesError.habitNotFound
        }

        let referenceDay = try LocalDay(date: clock.now, timeZone: timeZone)
        var day = try LocalDay(year: year, month: month, day: 1)
        var entries: [HabitEntry] = []

        while day.year == year && day.month == month {
            if day <= referenceDay {
                let completion = try await completionRepository.fetch(
                    habitID: habit.id,
                    completedOn: day
                )

                if habit.isTracked(
                    on: day,
                    hasCompletionOnArchiveDay: completion != nil
                ) {
                    let entry = try HabitEntry(
                        habit: habit,
                        targetDay: day,
                        completion: completion,
                        referenceDay: referenceDay
                    )
                    entries.append(entry)
                }
            }
            day = try day.addingDays(1)
        }
        return entries
    }
}

enum LoadMonthlyEntriesError: Error, Equatable {
    case habitNotFound
}
