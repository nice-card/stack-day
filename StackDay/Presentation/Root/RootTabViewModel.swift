//
//  RootTabViewModel.swift
//  StackDay
//

import Observation

@MainActor
@Observable
final class RootTabViewModel {
    enum Tab: Hashable {
        case today
        case statistics
    }

    let dayViewModel: DayViewModel
    let statisticsViewModel: StatisticsViewModel
    var selectedTab: Tab = .today

    init(
        dayViewModel: DayViewModel,
        statisticsViewModel: StatisticsViewModel
    ) {
        self.dayViewModel = dayViewModel
        self.statisticsViewModel = statisticsViewModel
    }
}
