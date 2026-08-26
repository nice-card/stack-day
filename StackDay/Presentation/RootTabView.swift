import SwiftUI

struct RootTabView: View {
    let dayViewModel: DayViewModel

    var body: some View {
        TabView {
            NavigationStack {
                DayView(viewModel: dayViewModel)
            }
            .tabItem {
                Label("Today", systemImage: "checkmark.circle")
            }
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar.xaxis")
            }
        }
    }
}

// TODO: PlaceHolder View

struct StatisticsView: View {
    var body: some View {
        ContentUnavailableView(
            "통계를 준비하고 있어요",
            systemImage: "chart.bar.xaxis",
            description: Text("Habit을 완료하면 통계를 확인할 수 있어요.")
        )
        .navigationTitle("Statistics")
    }
}
