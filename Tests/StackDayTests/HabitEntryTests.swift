//
//  HabitEntryTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct HabitEntryTests {
    private let recordedAt = Date(timeIntervalSince1970: 1_172_800)

    @Test("derives a completed entry from a matching completion")
    func completedEntry() throws {
        let referenceDay = try makeReferenceDay()
        let habit = try makeHabit()
        let completion = Completion(
            habitID: habit.id,
            completedOn: referenceDay,
            recordedAt: recordedAt
        )

        let entry = try HabitEntry(
            habit: habit,
            targetDay: referenceDay,
            completion: completion,
            referenceDay: referenceDay
        )

        #expect(entry.state == .completed)
    }

    @Test("derives today's incomplete entry as pending")
    func pendingEntry() throws {
        let referenceDay = try makeReferenceDay()
        let habit = try makeHabit()

        let entry = try HabitEntry(
            habit: habit,
            targetDay: referenceDay,
            completion: nil,
            referenceDay: referenceDay
        )

        #expect(entry.state == .pending)
    }

    @Test("derives a past incomplete entry as missed")
    func missedEntry() throws {
        let referenceDay = try makeReferenceDay()
        let pastDay = try referenceDay.addingDays(-1)
        let habit = try makeHabit()

        let entry = try HabitEntry(
            habit: habit,
            targetDay: pastDay,
            completion: nil,
            referenceDay: referenceDay
        )

        #expect(entry.state == .missed)
    }

    @Test("allows an entry on the archived habit's final tracking date")
    func allowsArchiveDate() throws {
        let referenceDay = try makeReferenceDay()
        let archivedOn = try referenceDay.addingDays(-1)
        let habit = try makeHabit(archivedOn: archivedOn)

        let entry = try HabitEntry(
            habit: habit,
            targetDay: archivedOn,
            completion: nil,
            referenceDay: referenceDay
        )

        #expect(entry.state == .missed)
    }

    private func makeStartDay() throws -> LocalDay {
        try LocalDay(
            year: 2026,
            month: 8,
            day: 18
        )
    }

    private func makeReferenceDay() throws -> LocalDay {
        try LocalDay(
            year: 2026,
            month: 8,
            day: 20
        )
    }

    private func makeHabit(
        archivedOn: LocalDay? = nil
    ) throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: makeStartDay(),
            archivedOn: archivedOn,
            createdAt: recordedAt
        )
    }
}
