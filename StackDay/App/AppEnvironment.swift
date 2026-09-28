//
//  AppEnvironment.swift
//  StackDay
//

import Foundation

struct AppEnvironment {
    let habitRepository: any HabitRepository
    let completionRepository: any CompletionRepository
    let habitStatisticCalculator: HabitStatisticsCalculator
    let clock: any Clock
    let timeZone: TimeZone

    init() throws {
        let applicationSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let directoryURL = applicationSupportURL.appendingPathComponent(
            "StackDay",
            isDirectory: true
        )

        habitRepository = FileHabitRepository(
            directoryURL: directoryURL,
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            fileManager: FileManager()
        )
        completionRepository = FileCompletionRepository(
            directoryURL: directoryURL,
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            fileManager: FileManager()
        )
        habitStatisticCalculator = HabitStatisticsCalculator()
        clock = SystemClock()
        timeZone = .current
    }
}
