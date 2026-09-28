//
//  HabitEntryTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

struct HabitEntryTests {
    private let startDate = Date(timeIntervalSince1970: 1_000_000)
    private let referenceDate = Date(timeIntervalSince1970: 1_172_800)

    @Test("derives a completed entry from a matching completion")
    func completedEntry() throws {
        let habit = try makeHabit()
        let completion = Completion(
            habitID: habit.id,
            completedOn: referenceDate,
            recordedAt: referenceDate
        )

        let entry = try HabitEntry(
            habit: habit,
            targetDate: referenceDate,
            completion: completion,
            referenceDate: referenceDate
        )

        #expect(entry.state == .completed)
    }

    @Test("derives today's incomplete entry as pending")
    func pendingEntry() throws {
        let habit = try makeHabit()

        let entry = try HabitEntry(
            habit: habit,
            targetDate: referenceDate,
            completion: nil,
            referenceDate: referenceDate
        )

        #expect(entry.state == .pending)
    }

    @Test("derives a past incomplete entry as missed")
    func missedEntry() throws {
        let habit = try makeHabit()
        let pastDate = referenceDate.addingTimeInterval(-86_400)

        let entry = try HabitEntry(
            habit: habit,
            targetDate: pastDate,
            completion: nil,
            referenceDate: referenceDate
        )

        #expect(entry.state == .missed)
    }

    @Test("allows an entry on the archived habit's final tracking date")
    func allowsArchiveDate() throws {
        let archivedOn = referenceDate.addingTimeInterval(-86_400)
        let habit = try makeHabit(archivedOn: archivedOn)

        let entry = try HabitEntry(
            habit: habit,
            targetDate: archivedOn,
            completion: nil,
            referenceDate: referenceDate
        )

        #expect(entry.state == .missed)
    }
    
    private func makeHabit(archivedOn: Date? = nil) throws -> Habit {
        try Habit(
            name: "Read",
            startedOn: startDate,
            archivedOn: archivedOn,
            createdAt: startDate
        )
    }
}
