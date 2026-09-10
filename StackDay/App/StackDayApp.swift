//
//  StackDayApp.swift
//  StackDay
//
//  Created by Kelly Dev on 6/29/26.
//

import SwiftUI

@main
struct StackDayApp: App {
    private let rootTabViewModelResult: Result<RootTabViewModel, Error>

    init() {
        let container = AppContainer()
        rootTabViewModelResult = Result {
            try container.makeRootTabViewModel()
        }
    }

    var body: some Scene {
        WindowGroup {
            switch rootTabViewModelResult {
            case .success(let rootTabViewModel):
                RootTabView(viewModel: rootTabViewModel)
            case .failure:
                ContentUnavailableView(
                    "앱을 시작할 수 없습니다",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
    }
}
