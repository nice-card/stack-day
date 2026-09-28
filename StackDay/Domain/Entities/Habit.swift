//
//  Habit.swift
//  StackDay
//

import Foundation

struct Habit: Equatable, Identifiable {
    let id: UUID
    private(set) var name: String
    let startedOn: LocalDay
    private(set) var trackingPeriods: [TrackingPeriod]
    let createdAt: Date
    private(set) var updatedAt: Date
    var isArchived: Bool {
        trackingPeriods.isEmpty || trackingPeriods.last?.endedOn != nil
    }

    init(
        id: UUID = UUID(),
        name: String,
        startedOn: LocalDay,
        createdAt: Date,
        updatedAt: Date? = nil
    ) throws {
        try self.init(
            id: id,
            name: name,
            startedOn: startedOn,
            trackingPeriods: [try TrackingPeriod(startedOn: startedOn)],
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    init(
        id: UUID = UUID(),
        name: String,
        startedOn: LocalDay,
        trackingPeriods: [TrackingPeriod],
        createdAt: Date,
        updatedAt: Date? = nil
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw HabitError.emptyName }
        try Self.validate(periods: trackingPeriods)
        self.id = id
        self.name = trimmedName
        self.startedOn = startedOn
        self.trackingPeriods = trackingPeriods
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    mutating func archive(
        on archiveActionDay: LocalDay,
        effectiveArchivedOn: LocalDay,
        updatedAt date: Date
    ) throws {
        guard var period = trackingPeriods.last, period.endedOn == nil else {
            throw HabitError.alreadyArchived
        }
        guard archiveActionDay >= period.startedOn else {
            throw HabitError.archiveBeforeCurrentTrackingPeriod
        }
        let dayBeforeArchiveAction = try archiveActionDay.addingDays(-1)
        guard effectiveArchivedOn == archiveActionDay ||
                effectiveArchivedOn == dayBeforeArchiveAction else {
            throw HabitError.invalidArchiveTrackingBoundary
        }
        if effectiveArchivedOn < period.startedOn {
            trackingPeriods.removeLast()
        } else {
            try period.end(on: effectiveArchivedOn)
            trackingPeriods[trackingPeriods.count - 1] = period
        }
        updatedAt = date
    }

    mutating func unarchive(on day: LocalDay, updatedAt date: Date) throws {
        guard !trackingPeriods.isEmpty else {
            trackingPeriods = [try TrackingPeriod(startedOn: day)]
            updatedAt = date
            return
        }
        guard var lastPeriod = trackingPeriods.last, let endedOn = lastPeriod.endedOn else {
            throw HabitError.notArchived
        }

        let dayAfterEnd = try endedOn.addingDays(1)
        if day <= dayAfterEnd {
            try lastPeriod.reopen()
            trackingPeriods[trackingPeriods.count - 1] = lastPeriod
        } else {
            trackingPeriods.append(try TrackingPeriod(startedOn: day))
        }
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
            throw HabitError.beforeHabitStart
        }
        guard targetDate <= referenceDay else {
            throw HabitError.futureDate
        }
        guard isTracked(on: targetDate) else {
            throw HabitError.outsideTrackingPeriod
        }
    }

    func isTracked(on targetDate: LocalDay) -> Bool {
        guard targetDate >= startedOn else { return false }
        return trackingPeriods.contains { $0.contains(targetDate) }
    }

    func trackingDays(through referenceDay: LocalDay) throws -> [LocalDay] {
        var days: [LocalDay] = []
        for period in trackingPeriods {
            guard period.startedOn <= referenceDay else { continue }
            let endDay = min(period.endedOn ?? referenceDay, referenceDay)
            var day = period.startedOn
            while day <= endDay {
                days.append(day)
                day = try day.addingDays(1)
            }
        }
        return days
    }

    private static func validate(periods: [TrackingPeriod]) throws {
        for index in periods.indices.dropLast() {
            guard let endedOn = periods[index].endedOn else {
                throw HabitError.invalidTrackingPeriods
            }
            let nextStart = periods[index + 1].startedOn
            let dayAfterEnd = try endedOn.addingDays(1)

            guard dayAfterEnd < nextStart else {
                throw HabitError.invalidTrackingPeriods
            }
        }
    }
}

enum HabitError: Error, Equatable {
    case emptyName
    case alreadyArchived
    case invalidArchiveTrackingBoundary
    case notArchived
    case invalidTrackingPeriods
    case beforeHabitStart
    case futureDate
    case outsideTrackingPeriod
    case archiveBeforeCurrentTrackingPeriod
}
