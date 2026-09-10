import SwiftUI

struct RootTabView: View {
    let viewModel: RootTabViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        TabView(selection: $viewModel.selectedTab) {
            NavigationStack {
                DayView(viewModel: viewModel.dayViewModel)
            }
            .tabItem {
                Label("Today", systemImage: "checkmark.circle")
            }
            .tag(RootTabViewModel.Tab.today)
            NavigationStack {
                StatisticsView(viewModel: viewModel.statisticsViewModel)
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar.xaxis")
            }
            .tag(RootTabViewModel.Tab.statistics)
        }
    }
}
