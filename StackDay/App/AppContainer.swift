//
//  AppContainer.swift
//  StackDay
//

import Foundation

final class AppContainer {
    private let habitRepository: any HabitRepository
    private let completionRepository: any CompletionRepository
    private let clock: any Clock
    private let timeZone: TimeZone

    init() {
        habitRepository = InMemoryHabitRepository()
        completionRepository = InMemoryCompletionRepository()
        clock = SystemClock()
        timeZone = .current
    }

    func makeCreateHabitUseCase() -> CreateHabitUseCase {
        CreateHabitUseCase(repository: habitRepository, clock: clock)
    }

    func makeArchiveHabitUseCase() -> ArchiveHabitUseCase {
        ArchiveHabitUseCase(
            repository: habitRepository,
            clock: clock,
            timeZone: timeZone
        )
    }

    func makeDeleteHabitUseCase() -> DeleteHabitUseCase {
        DeleteHabitUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository
        )
    }

    func makeLoadHabitStatisticsUseCase() -> LoadHabitStatisticsUseCase {
        LoadHabitStatisticsUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            clock: clock,
            timeZone: timeZone
        )
    }

    func makeLoadMonthlyEntriesUseCase() -> LoadMonthlyEntriesUseCase {
        LoadMonthlyEntriesUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            clock: clock,
            timeZone: timeZone
        )
    }

    func makeLoadTodayEntriesUseCase() -> LoadDayEntriesUseCase {
        LoadDayEntriesUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            clock: clock,
            timeZone: timeZone
        )
    }

    func makeRecordCompletionUseCase() -> RecordCompletionUseCase {
        RecordCompletionUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            clock: clock,
            timeZone: timeZone
        )
    }

    func makeCancelCompletionUseCase() -> CancelCompletionUseCase {
        CancelCompletionUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            clock: clock,
            timeZone: timeZone
        )
    }
}
