//
//  LoadHabitMonthlyCalendarUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct LoadHabitMonthlyCalendarUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_787_212_800)

    @Test("returns a cell for every day and assigns visible completion states")
    func returnsEveryDayWithCompletionStates() async throws {
        let startDay = try day(2026, 8, 18)
        let today = try day(2026, 8, 20)
        let habit = try Habit(name: "Read", startedOn: startDay, createdAt: now)
        let completion = Completion(
            habitID: habit.id,
            completedOn: try day(2026, 8, 19),
            recordedAt: now
        )
        let useCase = try makeUseCase(habits: [habit], completions: [completion], referenceDay: today)

        let calendar = try await useCase.execute(habitID: habit.id, year: 2026, month: 8)

        #expect(calendar.days.count == 31)
        #expect(calendar.days[0].state == .empty)
        #expect(calendar.days[17].state == .missed)
        #expect(calendar.days[18].state == .completed)
        #expect(calendar.days[19].state == .pending)
        #expect(calendar.days[19].isToday)
        #expect(calendar.days[20].state == .empty)
        #expect(calendar.canMoveToNextMonth == false)
    }

    @Test("keeps dates outside tracking periods empty")
    func keepsDatesOutsideTrackingPeriodsEmpty() async throws {
        let habit = try Habit(
            name: "Read",
            startedOn: try day(2026, 8, 1),
            trackingPeriods: [
                try TrackingPeriod(
                    startedOn: try day(2026, 8, 1),
                    endedOn: try day(2026, 8, 3)
                ),
                try TrackingPeriod(startedOn: try day(2026, 8, 10))
            ],
            createdAt: now
        )
        let useCase = try makeUseCase(
            habits: [habit],
            referenceDay: try day(2026, 8, 12)
        )

        let calendar = try await useCase.execute(habitID: habit.id, year: 2026, month: 8)

        #expect(calendar.days[2].state == .missed)
        #expect(calendar.days[3].state == .empty)
        #expect(calendar.days[8].state == .empty)
        #expect(calendar.days[9].state == .missed)
        #expect(calendar.days[11].state == .pending)
    }

    @Test("allows navigation toward the current month from a past month")
    func allowsNavigationTowardCurrentMonth() async throws {
        let habit = try Habit(
            name: "Read",
            startedOn: try day(2026, 7, 1),
            createdAt: now
        )
        let useCase = try makeUseCase(
            habits: [habit],
            referenceDay: try day(2026, 8, 20)
        )

        let calendar = try await useCase.execute(habitID: habit.id, year: 2026, month: 7)

        #expect(calendar.canMoveToNextMonth)
    }

    private func makeUseCase(
        habits: [Habit],
        completions: [Completion] = [],
        referenceDay: LocalDay
    ) throws -> LoadHabitMonthlyCalendarUseCase {
        LoadHabitMonthlyCalendarUseCase(
            habitRepository: RecordingHabitRepository(habits: habits),
            completionRepository: RecordingCompletionRepository(completions: completions),
            clock: FixedClock(now: try referenceDay.startDate(in: .gmt)),
            timeZone: .gmt
        )
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> LocalDay {
        try LocalDay(year: year, month: month, day: day)
    }
}
