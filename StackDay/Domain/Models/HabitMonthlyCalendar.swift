//
//  HabitMonthlyCalendar.swift
//  StackDay
//

struct HabitMonthlyCalendar: Equatable {
    let year: Int
    let month: Int
    let days: [HabitMonthlyCalendarDay]
    let canMoveToNextMonth: Bool
}

struct HabitMonthlyCalendarDay: Equatable, Identifiable {
    enum State: Equatable {
        case completed
        case missed
        case pending
        case empty
    }

    let date: LocalDay
    let state: State
    let isToday: Bool
    var id: LocalDay { date }
}
