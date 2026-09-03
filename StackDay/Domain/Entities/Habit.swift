//
//  Habit.swift
//  StackDay
//

import Foundation

struct Habit: Equatable, Identifiable {
    let id: UUID
    private(set) var name: String
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
            let dayBeforeStart = try startedOn.addingDays(-1)
            guard archivedOn == dayBeforeStart else {
                throw HabitError.archiveBeforeStart
            }
        }
        self.id = id
        self.name = trimmedName
        self.startedOn = startedOn
        self.archivedOn = archivedOn
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    mutating func archive(
        on archiveActionDay: LocalDay,
        effectiveArchivedOn: LocalDay,
        updatedAt date: Date
    ) throws {
        guard archivedOn == nil else { throw HabitError.alreadyArchived }
        if archiveActionDay < startedOn { throw HabitError.archiveBeforeStart }
        let dayBeforeArchiveAction = try archiveActionDay.addingDays(-1)
        guard effectiveArchivedOn == archiveActionDay ||
                effectiveArchivedOn == dayBeforeArchiveAction else {
            throw HabitError.invalidArchiveTrackingBoundary
        }
        archivedOn = effectiveArchivedOn
        updatedAt = date
    }

    mutating func rename(to name: String, updatedAt date: Date) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw HabitError.emptyName }

        self.name = trimmedName
        updatedAt = date
    }
    
    func validateRecordableDate(_ targetDate: LocalDay, referenceDay: LocalDay) throws {
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

    func isTracked(on targetDate: LocalDay) -> Bool {
        guard targetDate >= startedOn else { return false }
        guard let archivedOn else { return true }
        return targetDate <= archivedOn
    }
}

enum HabitError: Error, Equatable {
    case emptyName
    case archiveBeforeStart
    case alreadyArchived
    case invalidArchiveTrackingBoundary
}

enum HabitDateError: Error, Equatable {
    case beforeHabitStart
    case futureDate
    case afterHabitArchived
}
