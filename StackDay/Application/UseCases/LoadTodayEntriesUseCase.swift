//
//  LoadTodayEntriesUseCase.swift
//  StackDay
//

import Foundation

struct LoadTodayEntriesUseCase {
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

    func execute() async throws -> [HabitEntry] {
        let today = try LocalDay(date: clock.now, timeZone: timeZone)
        let habits = try await habitRepository.fetchAll()

        var entries: [HabitEntry] = []
        for habit in habits where isActive(habit, on: today) {
            let completion = try await completionRepository.fetch(
                habitID: habit.id,
                completedOn: today
            )
            let entry = try HabitEntry(
                habit: habit,
                targetDay: today,
                completion: completion,
                referenceDay: today
            )
            entries.append(entry)
        }

        return entries
    }

    private func isActive(_ habit: Habit, on day: LocalDay) -> Bool {
        guard habit.startedOn <= day else { return false }
        guard let archivedOn = habit.archivedOn else { return true }
        return day <= archivedOn
    }
}
