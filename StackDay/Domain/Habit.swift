//
//  Habit.swift
//  StackDay
//

import Foundation

struct Habit: Equatable {
    let id: UUID
    let name: String
    let startedOn: Date
    private(set) var archivedOn: Date?
    let createdAt: Date
    private(set) var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        startedOn: Date,
        archivedOn: Date? = nil,
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

    mutating func archive(on date: Date) throws {
        guard archivedOn == nil else { throw HabitError.alreadyArchived }
        if date < startedOn {
            throw HabitError.archiveBeforeStart
        }

        archivedOn = date
        updatedAt = date
    }
}

enum HabitError: Error, Equatable {
    case emptyName
    case archiveBeforeStart
    case alreadyArchived
}
