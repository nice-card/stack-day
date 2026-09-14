//
//  CompletionDTO.swift
//  StackDay
//

import Foundation

struct CompletionDTO: Codable {
    let id: UUID
    let habitID: UUID
    let completedOn: LocalDay
    let recordedAt: Date

    init(_ completion: Completion) {
        id = completion.id
        habitID = completion.habitID
        completedOn = completion.completedOn
        recordedAt = completion.recordedAt
    }

    func toDomain() -> Completion {
        Completion(
            id: id,
            habitID: habitID,
            completedOn: completedOn,
            recordedAt: recordedAt
        )
    }
}
