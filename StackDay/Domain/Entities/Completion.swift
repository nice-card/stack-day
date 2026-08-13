//
//  Completion.swift
//  StackDay
//
//  Created by Kelly Dev on 8/9/26.
//

import Foundation

struct Completion: Equatable {
    let id: UUID
    let habitID: UUID
    let completedOn: Date
    let recordedAt: Date

    init(
        id: UUID = UUID(),
        habitID: UUID,
        completedOn: Date,
        recordedAt: Date
    ) {
        self.id = id
        self.habitID = habitID
        self.completedOn = completedOn
        self.recordedAt = recordedAt
    }
}
