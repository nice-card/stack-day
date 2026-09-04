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

    @Test("derives a future entry without throwing")
    func futureEntry() throws {
        let referenceDay = try makeReferenceDay()
        let futureDay = try referenceDay.addingDays(1)
        let habit = try makeHabit()

        let entry = try HabitEntry(
            habit: habit,
            targetDay: futureDay,
            completion: nil,
            referenceDay: referenceDay
        )

        #expect(entry.state == .future)
    }

    @Test("allows an entry on the archived habit's final tracking date")
    func allowsArchiveDate() throws {
        let referenceDay = try makeReferenceDay()
        let periodEnd = try referenceDay.addingDays(-1)
        let habit = try makeHabit(endedOn: periodEnd)

        let entry = try HabitEntry(
            habit: habit,
            targetDay: periodEnd,
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
        endedOn: LocalDay? = nil
    ) throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: makeStartDay(),
            trackingPeriods: [
                try TrackingPeriod(startedOn: makeStartDay(), endedOn: endedOn)
            ],
            createdAt: recordedAt
        )
    }
}
