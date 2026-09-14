//
//  StatisticsViewModel.swift
//  StackDay
//

import Observation

@MainActor
@Observable
final class StatisticsViewModel {
    private let loadStatisticsOverviewUseCase: LoadStatisticsOverviewUseCase
    private let loadHabitStatisticsUseCase: LoadHabitStatisticsUseCase
    private let loadHabitMonthlyCalendarUseCase: LoadHabitMonthlyCalendarUseCase
    private let archiveHabitUseCase: ArchiveHabitUseCase
    private let unarchiveHabitUseCase: UnarchiveHabitUseCase
    private let deleteHabitUseCase: DeleteHabitUseCase
    private let initialCalendarMonth: LocalDay
    private var selectedCalendarMonth: LocalDay
    private(set) var activeSummaries: [HabitStatisticsSummary] = []
    private(set) var archivedSummaries: [HabitStatisticsSummary] = []
    private(set) var selectedHabitStatistics: HabitStatistics?
    private(set) var selectedHabitMonthlyCalendar: HabitMonthlyCalendar?
    private(set) var isLoading = false
    private(set) var alert: StatisticsAlert?

    init(
        loadStatisticsOverviewUseCase: LoadStatisticsOverviewUseCase,
        loadHabitStatisticsUseCase: LoadHabitStatisticsUseCase,
        loadHabitMonthlyCalendarUseCase: LoadHabitMonthlyCalendarUseCase,
        initialCalendarMonth: LocalDay,
        archiveHabitUseCase: ArchiveHabitUseCase,
        unarchiveHabitUseCase: UnarchiveHabitUseCase,
        deleteHabitUseCase: DeleteHabitUseCase
    ) {
        self.loadStatisticsOverviewUseCase = loadStatisticsOverviewUseCase
        self.loadHabitStatisticsUseCase = loadHabitStatisticsUseCase
        self.loadHabitMonthlyCalendarUseCase = loadHabitMonthlyCalendarUseCase
        self.initialCalendarMonth = initialCalendarMonth
        self.selectedCalendarMonth = initialCalendarMonth
        self.archiveHabitUseCase = archiveHabitUseCase
        self.unarchiveHabitUseCase = unarchiveHabitUseCase
        self.deleteHabitUseCase = deleteHabitUseCase
    }

    func viewAppeared() async {
        _ = await perform {
            try await self.loadSummaries()
        }
    }

    func habitStatisticsDetailRequested(for summary: HabitStatisticsSummary) async {
        _ = await perform {
            try await self.loadHabitStatistics(for: summary.id)
        }
    }

    func habitArchived(habitID: Habit.ID) async -> Bool {
        await perform {
            _ = try await self.archiveHabitUseCase.execute(habitID: habitID)
            try await self.loadSummaries()
        }
    }

    func habitUnarchived(habitID: Habit.ID) async -> Bool {
        await perform {
            _ = try await self.unarchiveHabitUseCase.execute(habitID: habitID)
            try await self.loadSummaries()
        }
    }

    func habitDeleted(habitID: Habit.ID) async -> Bool {
        await perform {
            try await self.deleteHabitUseCase.execute(habitID: habitID)
            try await self.loadSummaries()
        }
    }

    func dismissHabitStatisticsDetail() {
        selectedHabitStatistics = nil
        selectedHabitMonthlyCalendar = nil
    }

    func previousCalendarMonthRequested(for habitID: Habit.ID) async {
        guard !isLoading else { return }

        _ = await perform {
            let previousMonth = try self.selectedCalendarMonth.addingMonths(-1)
            try await self.loadMonthlyCalendar(
                habitID: habitID,
                month: previousMonth
            )
        }
    }

    func nextCalendarMonthRequested(for habitID: Habit.ID) async {
        guard !isLoading,
              selectedHabitMonthlyCalendar?.canMoveToNextMonth == true
        else { return }

        _ = await perform {
            let nextMonth = try self.selectedCalendarMonth.addingMonths(1)
            try await self.loadMonthlyCalendar(
                habitID: habitID,
                month: nextMonth
            )
        }
    }

    private func loadSummaries() async throws {
        let summaries = try await loadStatisticsOverviewUseCase.execute()
        activeSummaries = summaries.filter { !$0.isArchived }
        archivedSummaries = summaries.filter(\.isArchived)
    }

    private func loadHabitStatistics(for habitID: Habit.ID) async throws {
        selectedHabitStatistics = nil
        selectedHabitMonthlyCalendar = nil
        selectedCalendarMonth = initialCalendarMonth
        let statistics = try await loadHabitStatisticsUseCase.execute(habitID: habitID)
        let calendar = try await loadHabitMonthlyCalendarUseCase.execute(
            habitID: habitID,
            year: selectedCalendarMonth.year,
            month: selectedCalendarMonth.month
        )
        selectedHabitStatistics = statistics
        selectedHabitMonthlyCalendar = calendar
    }

    private func loadMonthlyCalendar(
        habitID: Habit.ID,
        month: LocalDay
    ) async throws {
        selectedHabitMonthlyCalendar = try await loadHabitMonthlyCalendarUseCase.execute(
            habitID: habitID,
            year: month.year,
            month: month.month
        )
        selectedCalendarMonth = month
    }

    private func perform(_ operation: @escaping () async throws -> Void) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await operation()
            return true
        } catch {
            alert = .operationFailed(String(describing: error))
            return false
        }
    }

    func dismissAlert() {
        alert = nil
    }
}

enum StatisticsAlert: Identifiable {
    case operationFailed(String)

    var id: String {
        switch self {
        case .operationFailed(let message): message
        }
    }

    var title: String {
        switch self {
        case .operationFailed: "Something went wrong"
        }
    }

    var message: String {
        switch self {
        case .operationFailed(let message): message
        }
    }
}
