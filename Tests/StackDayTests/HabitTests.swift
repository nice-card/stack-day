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
            try habit.validateDate(
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
            try habit.validateDate(
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
            try habit.validateDate(
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
            try habit.validateDate(
                archivedOn,
                referenceDay: archivedOn
            )
        }
    }

    private func makeStartedOn() throws -> LocalDay {
        try LocalDay(year: 2026, month: 8, day: 18)
    }
}
