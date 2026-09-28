//
//  HabitStatisticsDetailView.swift
//  StackDay
//

import SwiftUI

private struct StatisticMetric: Identifiable {
    let title: String
    let value: String

    var id: String { title }
}

struct HabitStatisticsDetailView: View {
    let summary: HabitStatisticsSummary
    let statistics: HabitStatistics?
    let calendar: HabitMonthlyCalendar?
    let isLoading: Bool
    let onAppear: () async -> Void
    let onArchive: () async -> Bool
    let onUnarchive: () async -> Bool
    let onDelete: () async -> Bool
    let onPreviousMonth: () async -> Void
    let onNextMonth: () async -> Void
    let onDisappear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingArchiveConfirmation = false
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        Group {
            if let statistics, let calendar {
                let rows = metricRows(for: statistics)
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        HabitMonthlyCalendarView(
                            calendarMonth: calendar,
                            isMonthNavigationDisabled: isLoading,
                            onPreviousMonth: {
                                Task { await onPreviousMonth() }
                            },
                            onNextMonth: {
                                Task { await onNextMonth() }
                            }
                        )

                        Grid(
                            alignment: .leading,
                            horizontalSpacing: 32,
                            verticalSpacing: 24
                        ) {
                            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                                GridRow {
                                    ForEach(row) { metric in
                                        statistic(metric)
                                    }
                                }

                                if index < rows.count - 1 {
                                    Divider()
                                        .gridCellColumns(2)
                                }
                            }
                        }
                        Divider()
                        HStack(spacing: 16) {
                            actionButton(
                                title: summary.isArchived ? "Unarchive" : "Archive",
                                isDestructive: false
                            ) {
                                if summary.isArchived {
                                    performAction(onUnarchive)
                                } else {
                                    isShowingArchiveConfirmation = true
                                }
                            }

                            actionButton(title: "Delete", isDestructive: true) {
                                isShowingDeleteConfirmation = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            } else {
                ProgressView("Loading statistics")
            }
        }
        .navigationTitle(summary.name)
        .task {
            await onAppear()
        }
        .onDisappear(perform: onDisappear)
        .alert("Archive Habit?", isPresented: $isShowingArchiveConfirmation) {
            Button("Archive") {
                performAction(onArchive)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Completion tracking pauses until you unarchive this habit.")
        }
        .alert("Delete Habit?", isPresented: $isShowingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                performAction(onDelete)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the habit and its completion history.")
        }
    }

    private func metricRows(for statistics: HabitStatistics) -> [[StatisticMetric]] {
        let metrics = [
            StatisticMetric(
                title: "Current Streak",
                value: "\(statistics.streak.current) days"
            ),
            StatisticMetric(
                title: "Longest Streak",
                value: "\(statistics.streak.longest) days"
            ),
            StatisticMetric(
                title: "Completed Days",
                value: "\(statistics.totalCompletedDays)"
            ),
            StatisticMetric(
                title: "Completion Rate",
                value: statistics.completionRate.formatted(
                    .percent.precision(.fractionLength(0))
                )
            )
        ]

        return stride(from: 0, to: metrics.count, by: 2).map { startIndex in
            Array(metrics[startIndex..<min(startIndex + 2, metrics.count)])
        }
    }

    private func statistic(_ metric: StatisticMetric) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(metric.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(metric.value)
                .font(.system(.largeTitle, design: .rounded).weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionButton(
        title: String,
        isDestructive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: isDestructive ? .destructive : nil, action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 64)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isDestructive ? .red : .primary)
        .background(Color(.secondarySystemBackground), in: Capsule())
    }

    private func performAction(_ action: @escaping () async -> Bool) {
        Task {
            if await action() {
                dismiss()
            }
        }
    }
}
