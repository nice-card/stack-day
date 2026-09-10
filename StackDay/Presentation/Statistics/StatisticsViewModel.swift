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
    private let archiveHabitUseCase: ArchiveHabitUseCase
    private let unarchiveHabitUseCase: UnarchiveHabitUseCase
    private let deleteHabitUseCase: DeleteHabitUseCase
    private(set) var activeSummaries: [HabitStatisticsSummary] = []
    private(set) var archivedSummaries: [HabitStatisticsSummary] = []
    private(set) var selectedHabitStatistics: HabitStatistics?
    private(set) var isLoading = false
    private(set) var alert: StatisticsAlert?

    init(
        loadStatisticsOverviewUseCase: LoadStatisticsOverviewUseCase,
        loadHabitStatisticsUseCase: LoadHabitStatisticsUseCase,
        archiveHabitUseCase: ArchiveHabitUseCase,
        unarchiveHabitUseCase: UnarchiveHabitUseCase,
        deleteHabitUseCase: DeleteHabitUseCase
    ) {
        self.loadStatisticsOverviewUseCase = loadStatisticsOverviewUseCase
        self.loadHabitStatisticsUseCase = loadHabitStatisticsUseCase
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
    }

    private func loadSummaries() async throws {
        let summaries = try await loadStatisticsOverviewUseCase.execute()
        activeSummaries = summaries.filter { !$0.isArchived }
        archivedSummaries = summaries.filter(\.isArchived)
    }

    private func loadHabitStatistics(for habitID: Habit.ID) async throws {
        selectedHabitStatistics = nil
        selectedHabitStatistics = try await loadHabitStatisticsUseCase.execute(habitID: habitID)
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
