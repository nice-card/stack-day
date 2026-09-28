//
//  HabitTests.swift
//  StackDayTests
//
//  Created by Kelly Dev on 8/13/26.
//

import Foundation
import Testing
@testable import StackDay

struct HabitTests {
    private let createdAt = Date(timeIntervalSince1970: 1_000_000)

    @Test("trims the name when creating a habit")
    func trimsName() throws {
        let startedOn = try makeStartedOn()

        let habit = try Habit(
            name: "  Read  ",
            startedOn: startedOn,
            createdAt: createdAt
        )

        #expect(habit.name == "Read")
    }

    @Test("rejects an empty name")
    func rejectsEmptyName() throws {
        let startedOn = try makeStartedOn()

        #expect(throws: HabitError.emptyName) {
            try Habit(
                name: " \n\t ",
                startedOn: startedOn,
                createdAt: createdAt
            )
        }
    }

    @Test("renames a habit, trims its name, and updates its timestamp")
    func renamesHabit() throws {
        let updatedAt = createdAt.addingTimeInterval(1)
        var habit = try Habit(
            name: "Read",
            startedOn: makeStartedOn(),
            createdAt: createdAt
        )

        try habit.rename(to: "  Exercise  ", updatedAt: updatedAt)

        #expect(habit.name == "Exercise")
        #expect(habit.updatedAt == updatedAt)
    }

    @Test("does not rename a habit to an empty name")
    func rejectsEmptyRenamedName() throws {
        var habit = try Habit(
            name: "Read",
            startedOn: makeStartedOn(),
            createdAt: createdAt
        )

        #expect(throws: HabitError.emptyName) {
            try habit.rename(
                to: " \n\t ",
                updatedAt: createdAt.addingTimeInterval(1)
            )
        }

        #expect(habit.name == "Read")
        #expect(habit.updatedAt == createdAt)
    }

    @Test("rejects archiving before the habit starts")
    func rejectsArchiveBeforeStart() throws {
        let startedOn = try makeStartedOn()
        let archiveDay = try startedOn.addingDays(-1)
        var habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )

        #expect(throws: HabitError.archiveBeforeCurrentTrackingPeriod) {
            try habit.archive(
                on: archiveDay,
                effectiveArchivedOn: archiveDay,
                updatedAt: createdAt
            )
        }
    }

    @Test("archives a habit and updates its timestamp")
    func archivesHabit() throws {
        let startedOn = try makeStartedOn()
        let periodEnd = try startedOn.addingDays(1)
        let updatedAt = createdAt.addingTimeInterval(1)

        var habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )

        try habit.archive(
            on: periodEnd,
            effectiveArchivedOn: periodEnd,
            updatedAt: updatedAt
        )

        #expect(habit.trackingPeriods.last?.endedOn == periodEnd)
        #expect(habit.updatedAt == updatedAt)
    }

    @Test("rejects archiving an archived habit")
    func rejectsArchivingAnArchivedHabit() throws {
        let startedOn = try makeStartedOn()
        let firstArchiveDay = try startedOn.addingDays(1)
        let secondArchiveDay = try firstArchiveDay.addingDays(1)

        var habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )

        try habit.archive(
            on: firstArchiveDay,
            effectiveArchivedOn: firstArchiveDay,
            updatedAt: createdAt
        )

        #expect(throws: HabitError.alreadyArchived) {
            try habit.archive(
                on: secondArchiveDay,
                effectiveArchivedOn: secondArchiveDay,
                updatedAt: createdAt
            )
        }
    }

    @Test("preserves the current period when an archive date precedes it")
    func rejectsArchiveBeforeCurrentTrackingPeriod() throws {
        let startedOn = try makeStartedOn()
        let firstArchiveDay = try startedOn.addingDays(9)
        let resumedOn = try startedOn.addingDays(19)
        var habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )

        try habit.archive(
            on: firstArchiveDay,
            effectiveArchivedOn: firstArchiveDay,
            updatedAt: createdAt
        )
        try habit.unarchive(on: resumedOn, updatedAt: createdAt)
        let periodsBeforeArchive = habit.trackingPeriods

        #expect(throws: HabitError.archiveBeforeCurrentTrackingPeriod) {
            try habit.archive(
                on: firstArchiveDay,
                effectiveArchivedOn: firstArchiveDay,
                updatedAt: createdAt
            )
        }

        #expect(habit.trackingPeriods == periodsBeforeArchive)
        #expect(habit.isTracked(on: resumedOn))
    }

    @Test("rejects tracking periods without an excluded day between them")
    func rejectsAdjacentTrackingPeriods() throws {
        let startedOn = try makeStartedOn()
        let firstPeriodEnd = try startedOn.addingDays(6)
        let nextPeriodStart = try firstPeriodEnd.addingDays(1)
        let periods = [
            try TrackingPeriod(startedOn: startedOn, endedOn: firstPeriodEnd),
            try TrackingPeriod(startedOn: nextPeriodStart)
        ]

        #expect(throws: HabitError.invalidTrackingPeriods) {
            try Habit(
                name: "Read",
                startedOn: startedOn,
                trackingPeriods: periods,
                createdAt: createdAt
            )
        }
    }

    @Test("allows tracking periods separated by an excluded day")
    func allowsSeparatedTrackingPeriods() throws {
        let startedOn = try makeStartedOn()
        let firstPeriodEnd = try startedOn.addingDays(6)
        let nextPeriodStart = try firstPeriodEnd.addingDays(2)
        let periods = [
            try TrackingPeriod(startedOn: startedOn, endedOn: firstPeriodEnd),
            try TrackingPeriod(startedOn: nextPeriodStart)
        ]

        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            trackingPeriods: periods,
            createdAt: createdAt
        )

        #expect(habit.trackingPeriods == periods)
    }

    @Test("rejects an archive boundary other than the action date or preceding day")
    func rejectsInvalidArchiveTrackingBoundary() throws {
        let startedOn = try makeStartedOn()
        let archiveActionDay = try startedOn.addingDays(2)
        let invalidBoundary = try archiveActionDay.addingDays(-2)
        var habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )

        #expect(throws: HabitError.invalidArchiveTrackingBoundary) {
            try habit.archive(
                on: archiveActionDay,
                effectiveArchivedOn: invalidBoundary,
                updatedAt: createdAt
            )
        }

        #expect(habit.isArchived == false)
    }

    @Test("rejects dates before the habit starts")
    func rejectsDateBeforeHabitStart() throws {
        let startedOn = try makeStartedOn()
        let targetDay = try startedOn.addingDays(-1)

        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )

        #expect(throws: HabitError.beforeHabitStart) {
            try habit.validateRecordableDate(
                targetDay,
                referenceDay: startedOn
            )
        }
    }

    @Test("rejects dates after the reference date")
    func rejectsFutureDate() throws {
        let startedOn = try makeStartedOn()
        let referenceDay = try startedOn.addingDays(1)
        let futureDay = try referenceDay.addingDays(1)

        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )

        #expect(throws: HabitError.futureDate) {
            try habit.validateRecordableDate(
                futureDay,
                referenceDay: referenceDay
            )
        }
    }

    @Test("rejects dates after the habit is archived")
    func rejectsDateAfterArchive() throws {
        let startedOn = try makeStartedOn()
        let periodEnd = try startedOn.addingDays(1)
        let dayAfterArchive = try periodEnd.addingDays(1)

        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            trackingPeriods: [
                try TrackingPeriod(startedOn: startedOn, endedOn: periodEnd)
            ],
            createdAt: createdAt
        )

        #expect(throws: HabitError.outsideTrackingPeriod) {
            try habit.validateRecordableDate(
                dayAfterArchive,
                referenceDay: dayAfterArchive
            )
        }
    }

    @Test("allows the archived tracking boundary")
    func allowsArchivedTrackingBoundary() throws {
        let startedOn = try makeStartedOn()
        let periodEnd = try startedOn.addingDays(1)

        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            trackingPeriods: [
                try TrackingPeriod(startedOn: startedOn, endedOn: periodEnd)
            ],
            createdAt: createdAt
        )

        #expect(throws: Never.self) {
            try habit.validateRecordableDate(
                periodEnd,
                referenceDay: periodEnd
            )
        }
    }

    @Test("tracks dates according to fixed start and archive boundaries")
    func tracksDatesAccordingToFixedBoundaries() throws {
        let startedOn = try makeStartedOn()
        let periodEnd = try startedOn.addingDays(1)
        let beforeStart = try startedOn.addingDays(-1)
        let beforeArchive = startedOn
        let afterArchive = try periodEnd.addingDays(1)
        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            trackingPeriods: [
                try TrackingPeriod(startedOn: startedOn, endedOn: periodEnd)
            ],
            createdAt: createdAt
        )

        #expect(
            habit.isTracked(on: beforeStart) == false
        )
        #expect(
            habit.isTracked(on: beforeArchive)
        )
        #expect(
            habit.isTracked(on: periodEnd)
        )
        #expect(
            habit.isTracked(on: afterArchive) == false
        )
    }

    @Test("has no archive boundary while active")
    func hasNoArchiveBoundaryWhileActive() throws {
        let habit = try Habit(
            name: "Read",
            startedOn: makeStartedOn(),
            createdAt: createdAt
        )

        #expect(habit.isArchived == false)
    }

    @Test("stores the effective archive boundary when archived")
    func storesEffectiveArchiveBoundaryWhenArchived() throws {
        let startedOn = try makeStartedOn()
        let archiveDay = try startedOn.addingDays(2)
        var habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )
        let expectedIncompleteFinalDay = try archiveDay.addingDays(-1)

        try habit.archive(
            on: archiveDay,
            effectiveArchivedOn: expectedIncompleteFinalDay,
            updatedAt: createdAt
        )

        #expect(habit.trackingPeriods.last?.endedOn == expectedIncompleteFinalDay)
    }

    @Test("returns days in an open tracking period through the reference day")
    func returnsOpenTrackingPeriodDays() throws {
        let startedOn = try makeStartedOn()
        let referenceDay = try startedOn.addingDays(2)
        let habit = try Habit(name: "Read", startedOn: startedOn, createdAt: createdAt)

        let trackingDays = try habit.trackingDays(through: referenceDay)

        #expect(trackingDays == [
            startedOn,
            try startedOn.addingDays(1),
            referenceDay
        ])
    }

    @Test("returns days in a closed tracking period through its end date")
    func returnsClosedTrackingPeriodDays() throws {
        let startedOn = try makeStartedOn()
        let endedOn = try startedOn.addingDays(1)
        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            trackingPeriods: [try TrackingPeriod(startedOn: startedOn, endedOn: endedOn)],
            createdAt: createdAt
        )

        let trackingDays = try habit.trackingDays(through: try endedOn.addingDays(2))

        #expect(trackingDays == [startedOn, endedOn])
    }

    @Test("returns no tracking days before the habit starts")
    func returnsNoTrackingDaysBeforeStart() throws {
        let startedOn = try makeStartedOn()
        let habit = try Habit(name: "Read", startedOn: startedOn, createdAt: createdAt)

        let trackingDays = try habit.trackingDays(through: try startedOn.addingDays(-1))

        #expect(trackingDays.isEmpty)
    }

    @Test("excludes dates between tracking periods")
    func excludesDaysBetweenTrackingPeriods() throws {
        let startedOn = try makeStartedOn()
        let firstPeriodEnd = try startedOn.addingDays(1)
        let resumedOn = try startedOn.addingDays(3)
        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            trackingPeriods: [
                try TrackingPeriod(startedOn: startedOn, endedOn: firstPeriodEnd),
                try TrackingPeriod(startedOn: resumedOn)
            ],
            createdAt: createdAt
        )

        let trackingDays = try habit.trackingDays(through: try resumedOn.addingDays(1))

        #expect(trackingDays == [
            startedOn,
            firstPeriodEnd,
            resumedOn,
            try resumedOn.addingDays(1)
        ])
    }

    @Test("excludes later tracking periods that start after the reference day")
    func excludesLaterTrackingPeriodsAfterReferenceDay() throws {
        let startedOn = try makeStartedOn()
        let laterPeriodStart = try startedOn.addingDays(3)
        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            trackingPeriods: [
                try TrackingPeriod(startedOn: startedOn, endedOn: startedOn),
                try TrackingPeriod(startedOn: laterPeriodStart)
            ],
            createdAt: createdAt
        )

        let trackingDays = try habit.trackingDays(through: try startedOn.addingDays(2))

        #expect(trackingDays == [startedOn])
    }

    @Test("returns no tracking days without tracking periods")
    func returnsNoTrackingDaysWithoutPeriods() throws {
        let startedOn = try makeStartedOn()
        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            trackingPeriods: [],
            createdAt: createdAt
        )

        let trackingDays = try habit.trackingDays(through: try startedOn.addingDays(2))

        #expect(trackingDays.isEmpty)
    }

    private func makeStartedOn() throws -> LocalDay {
        try LocalDay(year: 2026, month: 8, day: 18)
    }
}
