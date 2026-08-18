//
//  Completion.swift
//  StackDay
//
//  Created by Kelly Dev on 8/9/26.
//

import Foundation

struct Completion: Equatable, Identifiable {
    let id: UUID
    let habitID: UUID
    let completedOn: LocalDay
    let recordedAt: Date

    init(
        id: UUID = UUID(),
        habitID: UUID,
        completedOn: LocalDay,
        recordedAt: Date
    ) {
        self.id = id
        self.habitID = habitID
        self.completedOn = completedOn
        self.recordedAt = recordedAt
    }
}
