//
//  LoadTodayEntriesUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct LoadTodayEntriesUseCaseTests {
    @Test("returns active habits with their derived entry states")
    func returnsActiveHabitsWithDerivedStates() async throws {
        let today = try LocalDay(year: 2026, month: 8, day: 19)
        let completedHabit = try makeHabit(
            name: "Read",
            startedOn: today
        )
        let incompleteHabit = try makeHabit(
            name: "Walk",
            startedOn: today
        )
        let completion = Completion(
            habitID: completedHabit.id,
            completedOn: today,
            recordedAt: now
        )
        let useCase = makeUseCase(
            habits: [completedHabit, incompleteHabit],
            completions: [completion]
        )

        let entries = try await useCase.execute()

        let expectedEntries = [
            try HabitEntry(
                habit: completedHabit,
                targetDay: today,
                completion: completion,
                referenceDay: today
            ),
            try HabitEntry(
                habit: incompleteHabit,
                targetDay: today,
                completion: nil,
                referenceDay: today
            )
        ]

        #expect(entries == expectedEntries)
        #expect(entries.map(\.state) == [.completed, .pending])
    }

    @Test("excludes habits outside today's tracking period")
    func excludesHabitsOutsideTodayTrackingPeriod() async throws {
        let today = try LocalDay(year: 2026, month: 8, day: 19)
        let tomorrow = try today.addingDays(1)
        let yesterday = try today.addingDays(-1)

        let activeHabit = try makeHabit(
            name: "Read",
            startedOn: yesterday
        )
        let notStartedHabit = try makeHabit(
            name: "Walk",
            startedOn: tomorrow
        )
        let archivedBeforeToday = try makeHabit(
            name: "Journal",
            startedOn: yesterday,
            archivedOn: yesterday
        )
        let useCase = makeUseCase(
            habits: [
                activeHabit,
                notStartedHabit,
                archivedBeforeToday
            ]
        )

        let entries = try await useCase.execute()

        #expect(entries.map(\.habitID) == [activeHabit.id])
    }

    @Test("includes a habit on its archive day")
    func includesHabitOnArchiveDay() async throws {
        let today = try LocalDay(year: 2026, month: 8, day: 19)
        let habit = try makeHabit(
            name: "Read",
            startedOn: today,
            archivedOn: today
        )
        let useCase = makeUseCase(habits: [habit])

        let entries = try await useCase.execute()

        #expect(entries.count == 1)
        #expect(entries.first?.habitID == habit.id)
        #expect(entries.first?.state == .pending)
    }

    @Test("derives today from the injected clock and time zone")
    func derivesTodayFromInjectedClockAndTimeZone() async throws {
        let expectedToday = try LocalDay(
            year: 2026,
            month: 8,
            day: 19
        )
        let habit = try makeHabit(
            name: "Read",
            startedOn: expectedToday
        )
        let timeZone = try #require(
            TimeZone(secondsFromGMT: 9 * 60 * 60)
        )
        let clock = FixedClock(
            now: Date(timeIntervalSince1970: 1_787_148_000)
        )
        let useCase = LoadTodayEntriesUseCase(
            habitRepository: RecordingHabitRepository(
                habits: [habit]
            ),
            completionRepository: RecordingCompletionRepository(),
            clock: clock,
            timeZone: timeZone
        )

        let entries = try await useCase.execute()

        #expect(entries.first?.targetDay == expectedToday)
    }

    private let now = Date(
        timeIntervalSince1970: 1_787_126_400
    )

    private func makeUseCase(
        habits: [Habit],
        completions: [Completion] = []
    ) -> LoadTodayEntriesUseCase {
        LoadTodayEntriesUseCase(
            habitRepository: RecordingHabitRepository(
                habits: habits
            ),
            completionRepository: RecordingCompletionRepository(
                completions: completions
            ),
            clock: FixedClock(now: now),
            timeZone: .gmt
        )
    }

    private func makeHabit(
        name: String,
        startedOn: LocalDay,
        archivedOn: LocalDay? = nil
    ) throws -> Habit {
        try Habit(
            name: name,
            startedOn: startedOn,
            archivedOn: archivedOn,
            createdAt: now
        )
    }
}
