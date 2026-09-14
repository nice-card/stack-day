//
//  LoadHabitMonthlyCalendarUseCase.swift
//  StackDay
//

import Foundation

struct LoadHabitMonthlyCalendarUseCase {
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
    ) async throws -> HabitMonthlyCalendar {
        guard let habit = try await habitRepository.fetch(id: habitID) else {
            throw LoadHabitMonthlyCalendarError.habitNotFound
        }
        let referenceDay = try LocalDay(date: clock.now, timeZone: timeZone)
        let completedDays = Set(
            try await completionRepository.fetchAll(for: habitID)
                .map(\.completedOn)
        )
        var day = try LocalDay(year: year, month: month, day: 1)
        var days: [HabitMonthlyCalendarDay] = []
        while day.year == year && day.month == month {
            let state: HabitMonthlyCalendarDay.State
            if day > referenceDay || !habit.isTracked(on: day) {
                state = .empty
            } else if completedDays.contains(day) {
                state = .completed
            } else if day == referenceDay {
                state = .pending
            } else {
                state = .missed
            }
            days.append(
                HabitMonthlyCalendarDay(
                    date: day,
                    state: state,
                    isToday: day == referenceDay
                )
            )
            day = try day.addingDays(1)
        }

        return HabitMonthlyCalendar(
            year: year,
            month: month,
            days: days,
            canMoveToNextMonth: year < referenceDay.year ||
                (year == referenceDay.year && month < referenceDay.month)
        )
    }
}

enum LoadHabitMonthlyCalendarError: Error, Equatable {
    case habitNotFound
}
