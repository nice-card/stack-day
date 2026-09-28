//
//  StatisticsView.swift
//  StackDay
//

import SwiftUI

struct StatisticsView: View {
    private let viewModel: StatisticsViewModel

    init(viewModel: StatisticsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.activeSummaries.isEmpty && viewModel.archivedSummaries.isEmpty {
                ProgressView("Loading statistics")
            } else if viewModel.activeSummaries.isEmpty && viewModel.archivedSummaries.isEmpty {
                ContentUnavailableView(
                    "No habits yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Your habit statistics will appear here.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        Section {
                            ForEach(viewModel.activeSummaries) { summary in
                                summaryLink(summary)
                            }
                        }

                        if !viewModel.archivedSummaries.isEmpty {
                            Section {
                                ForEach(viewModel.archivedSummaries) { summary in
                                    summaryLink(summary)
                                }
                            } header: {
                                Text("Archived")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .gridCellColumns(gridColumns.count)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Statistics")
        .alert(
            item: Binding(
                get: { viewModel.alert },
                set: { _ in viewModel.dismissAlert() }
            )
        ) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK")) {
                    viewModel.dismissAlert()
                }
            )
        }
        .task {
            await viewModel.viewAppeared()
        }
    }

    private var gridColumns: [GridItem] {
        return [GridItem(.flexible()), GridItem(.flexible())]
    }

    private func summaryLink(_ summary: HabitStatisticsSummary) -> some View {
        NavigationLink {
            HabitStatisticsDetailView(
                summary: summary,
                statistics: viewModel.selectedHabitStatistics,
                calendar: viewModel.selectedHabitMonthlyCalendar,
                isLoading: viewModel.isLoading,
                onAppear: {
                    await viewModel.habitStatisticsDetailRequested(for: summary)
                },
                onArchive: {
                    await viewModel.habitArchived(habitID: summary.id)
                },
                onUnarchive: {
                    await viewModel.habitUnarchived(habitID: summary.id)
                },
                onDelete: {
                    await viewModel.habitDeleted(habitID: summary.id)
                },
                onPreviousMonth: {
                    await viewModel.previousCalendarMonthRequested(for: summary.id)
                },
                onNextMonth: {
                    await viewModel.nextCalendarMonthRequested(for: summary.id)
                },
                onDisappear: {
                    viewModel.dismissHabitStatisticsDetail()
                }
            )
        } label: {
            HabitStatisticsSummaryCard(summary: summary)
        }
        .buttonStyle(.plain)
    }
}
