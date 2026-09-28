//
//  LoadHabitStatisticsUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct LoadHabitStatisticsUseCaseTests {
    @Test("calculates statistics from the habit's completion records")
    func calculatesStatisticsFromHabitCompletions() async throws {
        let startDay = try day(2026, 8, 19)
        let habit = try makeHabit(startedOn: startDay)
        let completion = Completion(
            habitID: habit.id,
            completedOn: startDay,
            recordedAt: now
        )
        let useCase = makeUseCase(habits: [habit], completions: [completion])

        let statistics = try await useCase.execute(habitID: habit.id)

        #expect(statistics.totalCompletedDays == 1)
        #expect(statistics.eligibleTrackingDays == 2)
        #expect(statistics.completionRate == 0.5)
        #expect(statistics.streak == HabitStreak(current: 1, longest: 1))
    }

    @Test("returns habit not found for an unknown habit")
    func returnsHabitNotFoundForUnknownHabit() async {
        let useCase = makeUseCase()

        await #expect(throws: LoadHabitStatisticsError.habitNotFound) {
            try await useCase.execute(habitID: Habit.ID())
        }
    }

    @Test("uses the injected clock and time zone for the reference day")
    func usesInjectedClockAndTimeZoneForReferenceDay() async throws {
        let timeZone = try #require(
            TimeZone(secondsFromGMT: 9 * 60 * 60)
        )
        let startDay = try day(2026, 8, 20)
        let habit = try makeHabit(startedOn: startDay)
        let useCase = LoadHabitStatisticsUseCase(
            habitRepository: RecordingHabitRepository(habits: [habit]),
            completionRepository: RecordingCompletionRepository(),
            clock: FixedClock(now: Date(timeIntervalSince1970: 1_787_155_200)),
            timeZone: timeZone
        )

        let statistics = try await useCase.execute(habitID: habit.id)

        #expect(statistics.eligibleTrackingDays == 1)
    }

    @Test("uses the calculator's archive behavior without adding archive rules")
    func usesCalculatorArchiveBehavior() async throws {
        let startDay = try day(2026, 8, 18)
        let archiveDay = try day(2026, 8, 19)
        let afterArchiveDay = try day(2026, 8, 20)
        let habit = try makeHabit(
            startedOn: startDay,
            archivedOn: archiveDay
        )
        let completions = [startDay, archiveDay, afterArchiveDay].map {
            Completion(habitID: habit.id, completedOn: $0, recordedAt: now)
        }
        let useCase = makeUseCase(habits: [habit], completions: completions)

        let statistics = try await useCase.execute(habitID: habit.id)

        #expect(statistics.totalCompletedDays == 2)
        #expect(statistics.eligibleTrackingDays == 2)
        #expect(statistics.completionRate == 1)
        #expect(statistics.streak == HabitStreak(current: 2, longest: 2))
    }

    private let now = Date(timeIntervalSince1970: 1_787_212_800)

    private func makeUseCase(
        habits: [Habit] = [],
        completions: [Completion] = []
    ) -> LoadHabitStatisticsUseCase {
        LoadHabitStatisticsUseCase(
            habitRepository: RecordingHabitRepository(habits: habits),
            completionRepository: RecordingCompletionRepository(completions: completions),
            clock: FixedClock(now: now),
            timeZone: .gmt
        )
    }

    private func makeHabit(
        startedOn: LocalDay,
        archivedOn: LocalDay? = nil
    ) throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: startedOn,
            archivedOn: archivedOn,
            createdAt: now
        )
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> LocalDay {
        try LocalDay(year: year, month: month, day: day)
    }
}
