//
//  Habit.swift
//  StackDay
//

import Foundation

struct Habit: Equatable, Identifiable {
    let id: UUID
    let name: String
    let startedOn: LocalDay
    private(set) var archivedOn: LocalDay?
    let createdAt: Date
    private(set) var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        startedOn: LocalDay,
        archivedOn: LocalDay? = nil,
        createdAt: Date,
        updatedAt: Date? = nil
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw HabitError.emptyName }
        if let archivedOn, archivedOn < startedOn {
            throw HabitError.archiveBeforeStart
        }
        self.id = id
        self.name = trimmedName
        self.startedOn = startedOn
        self.archivedOn = archivedOn
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    mutating func archive(on day: LocalDay, updatedAt date: Date) throws {
        guard archivedOn == nil else { throw HabitError.alreadyArchived }
        if day < startedOn { throw HabitError.archiveBeforeStart }
        archivedOn = day
        updatedAt = date
    }
    
    func validateDate(_ targetDate: LocalDay, referenceDay: LocalDay) throws {
        guard targetDate >= startedOn else {
            throw HabitDateError.beforeHabitStart
        }
        guard targetDate <= referenceDay else {
            throw HabitDateError.futureDate
        }
        if let archivedOn, targetDate > archivedOn {
            throw HabitDateError.afterHabitArchived
        }
    }
}

enum HabitError: Error, Equatable {
    case emptyName
    case archiveBeforeStart
    case alreadyArchived
}

enum HabitDateError: Error, Equatable {
    case beforeHabitStart
    case futureDate
    case afterHabitArchived
}
