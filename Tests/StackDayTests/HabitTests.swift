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

    @Test("rejects an archive date before the habit starts")
    func rejectsArchiveBeforeStart() throws {
        let startedOn = try makeStartedOn()
        let archivedOn = try startedOn.addingDays(-2)

        #expect(throws: HabitError.archiveBeforeStart) {
            try Habit(
                name: "Read",
                startedOn: startedOn,
                archivedOn: archivedOn,
                createdAt: createdAt
            )
        }
    }

    @Test("archives a habit and updates its timestamp")
    func archivesHabit() throws {
        let startedOn = try makeStartedOn()
        let archivedOn = try startedOn.addingDays(1)
        let updatedAt = createdAt.addingTimeInterval(1)

        var habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )

        try habit.archive(
            on: archivedOn,
            effectiveArchivedOn: archivedOn,
            updatedAt: updatedAt
        )

        #expect(habit.archivedOn == archivedOn)
        #expect(habit.updatedAt == updatedAt)
    }

    @Test("rejects archiving an archived habit")
    func rejectsArchivingAnArchivedHabit() throws {
        let startedOn = try makeStartedOn()
        let archivedOn = try startedOn.addingDays(1)
        let secondArchiveDay = try archivedOn.addingDays(1)

        var habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )

        try habit.archive(
            on: archivedOn,
            effectiveArchivedOn: archivedOn,
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

        #expect(habit.archivedOn == nil)
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

        #expect(throws: HabitDateError.beforeHabitStart) {
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

        #expect(throws: HabitDateError.futureDate) {
            try habit.validateRecordableDate(
                futureDay,
                referenceDay: referenceDay
            )
        }
    }

    @Test("rejects dates after the habit is archived")
    func rejectsDateAfterArchive() throws {
        let startedOn = try makeStartedOn()
        let archivedOn = try startedOn.addingDays(1)
        let dayAfterArchive = try archivedOn.addingDays(1)

        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            archivedOn: archivedOn,
            createdAt: createdAt
        )

        #expect(throws: HabitDateError.afterHabitArchived) {
            try habit.validateRecordableDate(
                dayAfterArchive,
                referenceDay: dayAfterArchive
            )
        }
    }

    @Test("allows the archived tracking boundary")
    func allowsArchivedTrackingBoundary() throws {
        let startedOn = try makeStartedOn()
        let archivedOn = try startedOn.addingDays(1)

        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            archivedOn: archivedOn,
            createdAt: createdAt
        )

        #expect(throws: Never.self) {
            try habit.validateRecordableDate(
                archivedOn,
                referenceDay: archivedOn
            )
        }
    }

    @Test("tracks dates according to fixed start and archive boundaries")
    func tracksDatesAccordingToFixedBoundaries() throws {
        let startedOn = try makeStartedOn()
        let archivedOn = try startedOn.addingDays(1)
        let beforeStart = try startedOn.addingDays(-1)
        let beforeArchive = startedOn
        let afterArchive = try archivedOn.addingDays(1)
        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            archivedOn: archivedOn,
            createdAt: createdAt
        )

        #expect(
            habit.isTracked(on: beforeStart) == false
        )
        #expect(
            habit.isTracked(on: beforeArchive)
        )
        #expect(
            habit.isTracked(on: archivedOn)
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

        #expect(
            habit.archivedOn == nil
        )
    }

    @Test("stores the effective archive boundary when archived")
    func storesEffectiveArchiveBoundaryWhenArchived() throws {
        let startedOn = try makeStartedOn()
        let archivedOn = try startedOn.addingDays(2)
        var habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            createdAt: createdAt
        )
        let expectedIncompleteFinalDay = try archivedOn.addingDays(-1)

        try habit.archive(
            on: archivedOn,
            effectiveArchivedOn: expectedIncompleteFinalDay,
            updatedAt: createdAt
        )

        #expect(habit.archivedOn == expectedIncompleteFinalDay)
    }

    private func makeStartedOn() throws -> LocalDay {
        try LocalDay(year: 2026, month: 8, day: 18)
    }
}
