//
//  HabitDTO.swift
//  StackDay
//

import Foundation

struct HabitDTO: Codable {
    let id: UUID
    let name: String
    let startedOn: LocalDay
    let trackingPeriods: [TrackingPeriodDTO]
    let createdAt: Date
    let updatedAt: Date

    init(_ habit: Habit) {
        id = habit.id
        name = habit.name
        startedOn = habit.startedOn
        trackingPeriods = habit.trackingPeriods.map(TrackingPeriodDTO.init)
        createdAt = habit.createdAt
        updatedAt = habit.updatedAt
    }

    func toDomain() throws -> Habit {
        try Habit(
            id: id,
            name: name,
            startedOn: startedOn,
            trackingPeriods: try trackingPeriods.map { try $0.toDomain() },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct TrackingPeriodDTO: Codable {
    let startedOn: LocalDay
    let endedOn: LocalDay?

    init(_ trackingPeriod: TrackingPeriod) {
        startedOn = trackingPeriod.startedOn
        endedOn = trackingPeriod.endedOn
    }

    func toDomain() throws -> TrackingPeriod {
        try TrackingPeriod(startedOn: startedOn, endedOn: endedOn)
    }
}
