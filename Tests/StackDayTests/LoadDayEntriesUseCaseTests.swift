//
//  LoadDayEntriesUseCaseTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct LoadDayEntriesUseCaseTests {
    @Test("returns completed and missed entries for a past target day")
    func returnsEntriesForPastTargetDay() async throws {
        let targetDay = try day(2026, 8, 18)
        let referenceDay = try day(2026, 8, 19)

        let completedHabit = try makeHabit(
            name: "Read",
            startedOn: targetDay
        )
        let missedHabit = try makeHabit(
            name: "Walk",
            startedOn: targetDay
        )
        let completion = Completion(
            habitID: completedHabit.id,
            completedOn: targetDay,
            recordedAt: now
        )

        let useCase = try makeUseCase(
            habits: [completedHabit, missedHabit],
            completions: [completion],
            referenceDay: referenceDay
        )

        let entries = try await useCase.execute(on: targetDay)

        #expect(entries.map(\.targetDay) == [targetDay, targetDay])
        #expect(entries.map(\.state) == [.completed, .missed])
    }

    @Test("returns pending entries for the reference day")
    func returnsPendingEntriesForReferenceDay() async throws {
        let referenceDay = try day(2026, 8, 19)
        let habit = try makeHabit(
            name: "Read",
            startedOn: referenceDay
        )

        let useCase = try makeUseCase(
            habits: [habit],
            referenceDay: referenceDay
        )

        let entries = try await useCase.execute(on: referenceDay)

        #expect(entries.count == 1)
        #expect(entries.first?.state == .pending)
    }

    @Test("excludes habits outside the target day's tracking period")
    func excludesHabitsOutsideTargetDayTrackingPeriod() async throws {
        let targetDay = try day(2026, 8, 18)
        let referenceDay = try day(2026, 8, 19)
        let dayBefore = try targetDay.addingDays(-1)
        let dayAfter = try targetDay.addingDays(1)

        let activeHabit = try makeHabit(
            name: "Read",
            startedOn: dayBefore
        )
        let notStartedHabit = try makeHabit(
            name: "Walk",
            startedOn: dayAfter
        )
        let archivedHabit = try makeHabit(
            name: "Journal",
            startedOn: dayBefore,
            endedOn: dayBefore
        )

        let useCase = try makeUseCase(
            habits: [
                activeHabit,
                notStartedHabit,
                archivedHabit
            ],
            referenceDay: referenceDay
        )

        let entries = try await useCase.execute(on: targetDay)

        #expect(entries.map(\.habitID) == [activeHabit.id])
    }

    @Test("includes a habit on its archive day when it was completed")
    func includesCompletedHabitOnArchiveDay() async throws {
        let targetDay = try day(2026, 8, 18)
        let referenceDay = try day(2026, 8, 19)
        let habit = try makeHabit(
            name: "Read",
            startedOn: targetDay,
            endedOn: targetDay
        )

        let useCase = try makeUseCase(
            habits: [habit],
            completions: [
                Completion(
                    habitID: habit.id,
                    completedOn: targetDay,
                    recordedAt: now
                )
            ],
            referenceDay: referenceDay
        )

        let entries = try await useCase.execute(on: targetDay)

        #expect(entries.map(\.habitID) == [habit.id])
    }

    @Test("keeps an included archive day tracked after its completion is canceled")
    func keepsIncludedArchiveDayTrackedWithoutCompletion() async throws {
        let archiveDay = try day(2026, 8, 18)
        let habit = try makeHabit(
            name: "Read",
            startedOn: try archiveDay.addingDays(-1),
            endedOn: archiveDay
        )
        let useCase = try makeUseCase(
            habits: [habit],
            referenceDay: try archiveDay.addingDays(1)
        )

        let entries = try await useCase.execute(on: archiveDay)

        #expect(entries.map(\.state) == [.missed])
    }

    @Test("excludes an archive date that was outside the fixed period")
    func excludesArchiveDayOutsideFixedTrackingPeriod() async throws {
        let archiveDay = try day(2026, 8, 18)
        let habit = try makeHabit(
            name: "Read",
            startedOn: try archiveDay.addingDays(-1),
            endedOn: try archiveDay.addingDays(-1)
        )
        let useCase = try makeUseCase(
            habits: [habit],
            referenceDay: try archiveDay.addingDays(1)
        )

        let entries = try await useCase.execute(on: archiveDay)

        #expect(entries.isEmpty)
    }

    @Test("uses the injected clock and time zone as the reference day")
    func usesInjectedClockAndTimeZoneAsReferenceDay() async throws {
        let targetDay = try day(2026, 8, 19)
        let habit = try makeHabit(
            name: "Read",
            startedOn: targetDay
        )
        let timeZone = try #require(
            TimeZone(secondsFromGMT: 9 * 60 * 60)
        )

        let useCase = LoadDayEntriesUseCase(
            habitRepository: RecordingHabitRepository(
                habits: [habit]
            ),
            completionRepository: RecordingCompletionRepository(),
            clock: FixedClock(
                now: Date(timeIntervalSince1970: 1_787_148_000)
            ),
            timeZone: timeZone
        )

        let entries = try await useCase.execute(on: targetDay)

        #expect(entries.first?.state == .pending)
    }

    private let now = Date(
        timeIntervalSince1970: 1_787_126_400
    )

    private func makeUseCase(
        habits: [Habit],
        completions: [Completion] = [],
        referenceDay: LocalDay
    ) throws -> LoadDayEntriesUseCase {
        LoadDayEntriesUseCase(
            habitRepository: RecordingHabitRepository(
                habits: habits
            ),
            completionRepository: RecordingCompletionRepository(
                completions: completions
            ),
            clock: FixedClock(
                now: try referenceDay.startDate(in: .gmt)
            ),
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

    private func day(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) throws -> LocalDay {
        try LocalDay(
            year: year,
            month: month,
            day: day
        )
    }
}
