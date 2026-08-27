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
        let archivedOn = try startedOn.addingDays(-1)

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
            updatedAt: createdAt
        )

        #expect(throws: HabitError.alreadyArchived) {
            try habit.archive(
                on: secondArchiveDay,
                updatedAt: createdAt
            )
        }
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

    @Test("allows the archived date as the final valid date")
    func allowsArchiveDate() throws {
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

    @Test("tracks dates according to start and archive boundaries")
    func tracksDatesAccordingToBoundaries() throws {
        let startedOn = try makeStartedOn()
        let archivedOn = try startedOn.addingDays(2)
        let beforeStart = try startedOn.addingDays(-1)
        let beforeArchive = try startedOn.addingDays(1)
        let afterArchive = try archivedOn.addingDays(1)
        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            archivedOn: archivedOn,
            createdAt: createdAt
        )

        #expect(
            habit.isTracked(
                on: beforeStart,
                hasCompletionOnArchiveDay: false
            ) == false
        )
        #expect(
            habit.isTracked(
                on: beforeArchive,
                hasCompletionOnArchiveDay: false
            )
        )
        #expect(
            habit.isTracked(
                on: archivedOn,
                hasCompletionOnArchiveDay: false
            ) == false
        )
        #expect(
            habit.isTracked(
                on: archivedOn,
                hasCompletionOnArchiveDay: true
            )
        )
        #expect(
            habit.isTracked(
                on: afterArchive,
                hasCompletionOnArchiveDay: true
            ) == false
        )
    }

    @Test("uses today as the effective end date for an active habit")
    func returnsNilFinalTrackingDateForActiveHabit() throws {
        let habit = try Habit(
            name: "Read",
            startedOn: makeStartedOn(),
            createdAt: createdAt
        )

        #expect(
            try habit.finalTrackingDate(
                hasCompletionOnArchiveDate: false
            ) == nil
        )
    }

    @Test("uses the archive date only when it has a completion")
    func calculatesFinalTrackingDateFromArchiveCompletion() throws {
        let startedOn = try makeStartedOn()
        let archivedOn = try startedOn.addingDays(2)
        let habit = try Habit(
            name: "Read",
            startedOn: startedOn,
            archivedOn: archivedOn,
            createdAt: createdAt
        )

        let completedArchiveFinalDay = try habit.finalTrackingDate(
            hasCompletionOnArchiveDate: true
        )
        let incompleteArchiveFinalDay = try habit.finalTrackingDate(
            hasCompletionOnArchiveDate: false
        )
        let expectedIncompleteFinalDay = try archivedOn.addingDays(-1)

        #expect(completedArchiveFinalDay == archivedOn)
        #expect(incompleteArchiveFinalDay == expectedIncompleteFinalDay)
    }

    private func makeStartedOn() throws -> LocalDay {
        try LocalDay(year: 2026, month: 8, day: 18)
    }
}
