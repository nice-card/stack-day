//
//  AppContainer.swift
//  StackDay
//

import Foundation

final class AppContainer {
    private let habitRepository: any HabitRepository
    private let completionRepository: any CompletionRepository
    private let habitStatisticCalculator: HabitStatisticsCalculator
    private let clock: any Clock
    private let timeZone: TimeZone

    init() {
        habitRepository = InMemoryHabitRepository()
        completionRepository = InMemoryCompletionRepository()
        habitStatisticCalculator = HabitStatisticsCalculator()
        clock = SystemClock()
        timeZone = .current
    }

    func makeCreateHabitUseCase() -> CreateHabitUseCase {
        CreateHabitUseCase(repository: habitRepository, clock: clock)
    }

    func makeArchiveHabitUseCase() -> ArchiveHabitUseCase {
        ArchiveHabitUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            clock: clock,
            timeZone: timeZone
        )
    }

    func makeUnarchiveHabitUseCase() -> UnarchiveHabitUseCase {
        UnarchiveHabitUseCase(
            habitRepository: habitRepository,
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

    func makeRenameHabitUseCase() -> RenameHabitUseCase {
        RenameHabitUseCase(
            habitRepository: habitRepository,
            clock: clock
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

    func makeLoadDayEntriesUseCase() -> LoadDayEntriesUseCase {
        LoadDayEntriesUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            clock: clock,
            timeZone: timeZone
        )
    }

    func makeLoadStatisticsOverviewUseCase() -> LoadStatisticsOverviewUseCase {
        LoadStatisticsOverviewUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            calculator: habitStatisticCalculator,
            clock: clock,
            timeZone: timeZone
        )
    }
    
    func makeLoadHabitDetailUseCase() -> LoadHabitDetailUseCase {
        LoadHabitDetailUseCase(habitRepository: habitRepository)
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

    @MainActor
    func makeDayViewModel() throws -> DayViewModel {
        let selectedDay = try LocalDay(date: clock.now, timeZone: timeZone)
        return DayViewModel(
            selectedDay: selectedDay,
            loadDayEntriesUseCase: makeLoadDayEntriesUseCase(),
            recordCompletionUseCase: makeRecordCompletionUseCase(),
            cancelCompletionUseCase: makeCancelCompletionUseCase(),
            createHabitUseCase: makeCreateHabitUseCase(),
            loadHabitDetailUseCase: makeLoadHabitDetailUseCase(),
            renameHabitUseCase: makeRenameHabitUseCase(),
            archiveHabitUseCase: makeArchiveHabitUseCase(),
            unarchiveHabitUseCase: makeUnarchiveHabitUseCase(),
            deleteHabitUseCase: makeDeleteHabitUseCase()
        )
    }

    @MainActor
    func makeStatisticsViewModel() -> StatisticsViewModel {
        StatisticsViewModel(
            loadStatisticsOverviewUseCase: makeLoadStatisticsOverviewUseCase()
        )
    }

    @MainActor
    func makeRootTabViewModel() throws -> RootTabViewModel {
        RootTabViewModel(
            dayViewModel: try makeDayViewModel(),
            statisticsViewModel: makeStatisticsViewModel()
        )
    }
}
