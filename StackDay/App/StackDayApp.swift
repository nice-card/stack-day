//
//  StackDayApp.swift
//  StackDay
//
//  Created by Kelly Dev on 6/29/26.
//

import SwiftUI

@main
struct StackDayApp: App {
    private let dayViewModelResult: Result<DayViewModel, Error>

    init() {
        let container = AppContainer()
        dayViewModelResult = Result {
            try container.makeDayViewModel()
        }
    }

    var body: some Scene {
        WindowGroup {
            switch dayViewModelResult {
            case .success(let viewModel):
                NavigationStack {
                    DayView(viewModel: viewModel)
                }

            case .failure:
                ContentUnavailableView(
                    "앱을 시작할 수 없습니다",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
    }
}
