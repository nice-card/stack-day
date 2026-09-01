//
//  LoadTodayEntriesUseCase.swift
//  StackDay
//

import Foundation

struct LoadDayEntriesUseCase {
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

    func execute(on targetDay: LocalDay) async throws -> [HabitEntry] {
        let referenceDay = try LocalDay(
            date: clock.now,
            timeZone: timeZone
        )
        let habits = try await habitRepository.fetchAll()

        var entries: [HabitEntry] = []

        for habit in habits {
            guard habit.isTracked(on: targetDay) else {
                continue
            }

            let completion = try await completionRepository.fetch(
                habitID: habit.id,
                completedOn: targetDay
            )

            let entry = try HabitEntry(
                habit: habit,
                targetDay: targetDay,
                completion: completion,
                referenceDay: referenceDay
            )

            entries.append(entry)
        }

        return entries
    }
}
