//
//  LoadMonthlyEntriesUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct LoadMonthlyEntriesUseCaseTests {
    @Test("returns leap-day entries within the requested month")
    func returnsLeapDayEntriesWithinRequestedMonth() async throws {
        let february28 = try day(2024, 2, 28)
        let february29 = try day(2024, 2, 29)
        let habit = try makeHabit(startedOn: february28)
        let completion = Completion(
            habitID: habit.id,
            completedOn: february29,
            recordedAt: now
        )
        let useCase = try makeUseCase(
            habits: [habit],
            completions: [completion],
            referenceDay: february29
        )

        let entries = try await useCase.execute(
            habitID: habit.id,
            year: 2024,
            month: 2
        )

        #expect(entries.map(\.targetDay) == [february28, february29])
        #expect(entries.map(\.state) == [.missed, .completed])
    }

    @Test("limits entries to a habit's start and archive boundaries")
    func limitsEntriesToHabitTrackingPeriod() async throws {
        let startDay = try day(2026, 8, 18)
        let archiveDay = try day(2026, 8, 19)
        let habit = try makeHabit(
            startedOn: startDay,
            archivedOn: archiveDay
        )
        let useCase = try makeUseCase(
            habits: [habit],
            completions: [
                Completion(
                    habitID: habit.id,
                    completedOn: archiveDay,
                    recordedAt: now
                )
            ],
            referenceDay: try day(2026, 8, 31)
        )

        let entries = try await useCase.execute(
            habitID: habit.id,
            year: 2026,
            month: 8
        )

        #expect(entries.map(\.targetDay) == [startDay, archiveDay])
    }

    @Test("excludes an incomplete archive date from monthly entries")
    func excludesIncompleteArchiveDate() async throws {
        let startDay = try day(2026, 8, 18)
        let archiveDay = try day(2026, 8, 19)
        let habit = try makeHabit(
            startedOn: startDay,
            archivedOn: try archiveDay.addingDays(-1)
        )
        let useCase = try makeUseCase(
            habits: [habit],
            referenceDay: try day(2026, 8, 31)
        )

        let entries = try await useCase.execute(
            habitID: habit.id,
            year: 2026,
            month: 8
        )

        #expect(entries.map(\.targetDay) == [startDay])
    }

    @Test("excludes future days from the current and future months")
    func excludesFutureDays() async throws {
        let startDay = try day(2026, 8, 1)
        let today = try day(2026, 8, 19)
        let habit = try makeHabit(startedOn: startDay)
        let useCase = try makeUseCase(
            habits: [habit],
            referenceDay: today
        )

        let currentMonthEntries = try await useCase.execute(
            habitID: habit.id,
            year: 2026,
            month: 8
        )
        let futureMonthEntries = try await useCase.execute(
            habitID: habit.id,
            year: 2026,
            month: 9
        )

        let expectedDays = try (1...19).map {
            try LocalDay(year: 2026, month: 8, day: $0)
        }
        #expect(currentMonthEntries.map(\.targetDay) == expectedDays)
        #expect(currentMonthEntries.last?.state == .pending)
        #expect(futureMonthEntries.isEmpty)
    }

    @Test("matches completions by habit and target day")
    func matchesCompletionsByHabitAndTargetDay() async throws {
        let targetDay = try day(2026, 8, 19)
        let habit = try makeHabit(startedOn: targetDay)
        let otherHabit = try makeHabit(name: "Walk", startedOn: targetDay)
        let completion = Completion(
            habitID: habit.id,
            completedOn: targetDay,
            recordedAt: now
        )
        let unrelatedCompletion = Completion(
            habitID: otherHabit.id,
            completedOn: targetDay,
            recordedAt: now
        )
        let useCase = try makeUseCase(
            habits: [habit],
            completions: [completion, unrelatedCompletion],
            referenceDay: targetDay
        )

        let entries = try await useCase.execute(
            habitID: habit.id,
            year: 2026,
            month: 8
        )

        #expect(entries == [
            try HabitEntry(
                habit: habit,
                targetDay: targetDay,
                completion: completion,
                referenceDay: targetDay
            )
        ])
    }

    @Test("does not cross the requested month boundary")
    func doesNotCrossRequestedMonthBoundary() async throws {
        let january31 = try day(2026, 1, 31)
        let february1 = try day(2026, 2, 1)
        let habit = try makeHabit(
            startedOn: january31,
            archivedOn: february1
        )
        let useCase = try makeUseCase(
            habits: [habit],
            completions: [
                Completion(
                    habitID: habit.id,
                    completedOn: february1,
                    recordedAt: now
                )
            ],
            referenceDay: february1
        )

        let entries = try await useCase.execute(
            habitID: habit.id,
            year: 2026,
            month: 2
        )

        #expect(entries.map(\.targetDay) == [february1])
    }

    @Test("returns habit not found for an unknown habit")
    func returnsHabitNotFoundForUnknownHabit() async throws {
        let useCase = try makeUseCase(
            referenceDay: try day(2026, 8, 19)
        )

        await #expect(throws: LoadMonthlyEntriesError.habitNotFound) {
            try await useCase.execute(
                habitID: Habit.ID(),
                year: 2026,
                month: 8
            )
        }
    }
    
    @Test("rejects an invalid month")
    func rejectsInvalidMonth() async throws {
        let habit = try makeHabit(
            startedOn: try day(2026, 8, 1)
        )
        let useCase = try makeUseCase(
            habits: [habit],
            referenceDay: try day(2026, 8, 19)
        )

        await #expect(throws: LocalDayError.invalidDate) {
            try await useCase.execute(
                habitID: habit.id,
                year: 2026,
                month: 13
            )
        }
    }

    private let now = Date(timeIntervalSince1970: 1_787_126_400)

    private func makeUseCase(
        habits: [Habit] = [],
        completions: [Completion] = [],
        referenceDay: LocalDay
    ) throws -> LoadMonthlyEntriesUseCase {
        LoadMonthlyEntriesUseCase(
            habitRepository: RecordingHabitRepository(habits: habits),
            completionRepository: RecordingCompletionRepository(
                completions: completions
            ),
            clock: FixedClock(now: try referenceDay.startDate(in: .gmt)),
            timeZone: .gmt
        )
    }

    private func makeHabit(
        name: String = "Read",
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

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> LocalDay {
        try LocalDay(year: year, month: month, day: day)
    }
}
