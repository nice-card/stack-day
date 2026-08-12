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
    private let startedOn = Date(timeIntervalSince1970: 1_086_400)

    @Test("trims the name when creating a habit")
    func trimsName() throws {
        let habit = try Habit(
            name: "  Read  ",
            startedOn: startedOn,
            createdAt: createdAt
        )

        #expect(habit.name == "Read")
    }

    @Test("rejects an empty name")
    func rejectsEmptyName() {
        #expect(throws: HabitError.emptyName) {
            try Habit(name: " \n\t ", startedOn: startedOn, createdAt: createdAt)
        }
    }

    @Test("rejects an archive date before the habit starts")
    func rejectsArchiveBeforeStart() {
        #expect(throws: HabitError.archiveBeforeStart) {
            try Habit(
                name: "Read",
                startedOn: startedOn,
                archivedOn: startedOn.addingTimeInterval(-86_400),
                createdAt: createdAt
            )
        }
    }

    @Test("archives a habit and updates its timestamp")
    mutating func archivesHabit() throws {
        var habit = try Habit(name: "Read", startedOn: startedOn, createdAt: createdAt)
        let archivedOn = startedOn.addingTimeInterval(86_400)

        try habit.archive(on: archivedOn)

        #expect(habit.archivedOn == archivedOn)
        #expect(habit.updatedAt == archivedOn)
    }

    @Test("rejects archiving an archived habit")
    func rejectsArchivingAnArchivedHabit() throws {
        var habit = try Habit(name: "Read", startedOn: startedOn, createdAt: createdAt)
        let archivedOn = startedOn.addingTimeInterval(86_400)

        try habit.archive(on: archivedOn)

        #expect(throws: HabitError.alreadyArchived) {
            try habit.archive(on: archivedOn.addingTimeInterval(86_400))
        }
    }
}
