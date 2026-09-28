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

        #expect(
            statistics == HabitStatistics(
                totalCompletedDays: 1,
                eligibleTrackingDays: 2,
                completionRate: 0.5,
                streak: HabitStreak(current: 1, longest: 1)
            )
        )
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

        #expect(
            statistics == HabitStatistics(
                totalCompletedDays: 0,
                eligibleTrackingDays: 1,
                completionRate: 0,
                streak: HabitStreak(current: 0, longest: 0)
            )
        )
    }

    @Test("prepares eligible and completed days from an archived habit")
    func preparesEligibleAndCompletedDaysFromArchivedHabit() async throws {
        let startDay = try day(2026, 8, 18)
        let archiveDay = try day(2026, 8, 19)
        let afterArchiveDay = try day(2026, 8, 20)
        let habit = try makeHabit(
            startedOn: startDay,
            endedOn: archiveDay
        )
        let completions = [startDay, archiveDay, afterArchiveDay].map {
            Completion(habitID: habit.id, completedOn: $0, recordedAt: now)
        }
        let useCase = makeUseCase(habits: [habit], completions: completions)

        let statistics = try await useCase.execute(habitID: habit.id)

        #expect(
            statistics == HabitStatistics(
                totalCompletedDays: 2,
                eligibleTrackingDays: 2,
                completionRate: 1,
                streak: HabitStreak(current: 2, longest: 2)
            )
        )
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
        endedOn: LocalDay? = nil
    ) throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: startedOn,
            trackingPeriods: [
                try TrackingPeriod(startedOn: startedOn, endedOn: endedOn)
            ],
            createdAt: now
        )
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> LocalDay {
        try LocalDay(year: year, month: month, day: day)
    }
}
