//
//  LoadStatisticsOverviewUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct LoadStatisticsOverviewUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_787_212_800)

    @Test("returns summaries for active and archived habits")
    func returnsActiveAndArchivedHabitSummaries() async throws {
        let activeStartDay = try day(2026, 8, 19)
        let archivedStartDay = try day(2026, 8, 18)
        let archivedEndDay = try day(2026, 8, 19)
        let activeHabit = try makeHabit(name: "Read", startedOn: activeStartDay)
        let archivedHabit = try makeHabit(
            name: "Exercise",
            startedOn: archivedStartDay,
            endedOn: archivedEndDay
        )
        let completions = [
            Completion(habitID: activeHabit.id, completedOn: activeStartDay, recordedAt: now),
            Completion(habitID: archivedHabit.id, completedOn: archivedStartDay, recordedAt: now),
            Completion(habitID: archivedHabit.id, completedOn: archivedEndDay, recordedAt: now)
        ]
        let useCase = makeUseCase(
            habits: [activeHabit, archivedHabit],
            completions: completions
        )

        let summaries = try await useCase.execute()

        let activeSummary = try #require(
            summaries.first { $0.id == activeHabit.id }
        )
        #expect(activeSummary.name == "Read")
        #expect(activeSummary.isArchived == false)
        #expect(activeSummary.currentStreak == 1)
        #expect(activeSummary.completionRate == 0.5)

        let archivedSummary = try #require(
            summaries.first { $0.id == archivedHabit.id }
        )
        #expect(archivedSummary.name == "Exercise")
        #expect(archivedSummary.isArchived)
        #expect(archivedSummary.currentStreak == 2)
        #expect(archivedSummary.completionRate == 1)
    }

    @Test("excludes completion records outside a tracking period")
    func excludesCompletionRecordsOutsideTrackingPeriods() async throws {
        let startedOn = try day(2026, 8, 18)
        let endedOn = try day(2026, 8, 19)
        let outsidePeriodDay = try day(2026, 8, 20)
        let habit = try makeHabit(
            name: "Read",
            startedOn: startedOn,
            endedOn: endedOn
        )
        let completions = [
            Completion(habitID: habit.id, completedOn: startedOn, recordedAt: now),
            Completion(habitID: habit.id, completedOn: endedOn, recordedAt: now),
            Completion(habitID: habit.id, completedOn: outsidePeriodDay, recordedAt: now)
        ]
        let useCase = makeUseCase(habits: [habit], completions: completions)

        let summaries = try await useCase.execute()
        let summary = try #require(summaries.first)

        #expect(summary.currentStreak == 2)
        #expect(summary.completionRate == 1)
    }

    @Test("returns no summaries without habits")
    func returnsNoSummariesWithoutHabits() async throws {
        let summaries = try await makeUseCase().execute()

        #expect(summaries.isEmpty)
    }

    private func makeUseCase(
        habits: [Habit] = [],
        completions: [Completion] = []
    ) -> LoadStatisticsOverviewUseCase {
        LoadStatisticsOverviewUseCase(
            habitRepository: RecordingHabitRepository(habits: habits),
            completionRepository: RecordingCompletionRepository(completions: completions),
            calculator: HabitStatisticsCalculator(),
            clock: FixedClock(now: now),
            timeZone: .gmt
        )
    }

    private func makeHabit(
        name: String,
        startedOn: LocalDay,
        endedOn: LocalDay? = nil
    ) throws -> Habit {
        try Habit(
            name: name,
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
