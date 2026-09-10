//
//  StatisticsViewModel.swift
//  StackDay
//

import Observation

@MainActor
@Observable
final class StatisticsViewModel {
    private let loadStatisticsOverviewUseCase: LoadStatisticsOverviewUseCase
    private(set) var activeSummaries: [HabitStatisticsSummary] = []
    private(set) var archivedSummaries: [HabitStatisticsSummary] = []
    private(set) var isLoading = false
    private(set) var alert: StatisticsAlert?

    init(loadStatisticsOverviewUseCase: LoadStatisticsOverviewUseCase) {
        self.loadStatisticsOverviewUseCase = loadStatisticsOverviewUseCase
    }

    func loadSummaries() async {
        await perform {
            let summaries = try await self.loadStatisticsOverviewUseCase.execute()
            self.activeSummaries = summaries.filter { !$0.isArchived }
            self.archivedSummaries = summaries.filter(\.isArchived)
        }
    }

    func viewAppeared() async {
        await loadSummaries()
    }

    private func perform(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await operation()
        } catch {
            alert = .operationFailed(String(describing: error))
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
