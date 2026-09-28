//
//  DayView.swift
//  StackDay
//

import SwiftUI

struct DayView: View {
    @State private var isShowingAddHabit = false

    private let viewModel: DayViewModel

    init(viewModel: DayViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 0) {
            if viewModel.entries.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "오늘의 Habit이 없어요",
                        systemImage: "checkmark.circle",
                        description: Text("+ 버튼으로 Habit을 추가해보세요.")
                    )
                } else {
                    List {
                        entrySection(title: nil, entries: pendingEntries)
                        entrySection(title: "Completed", entries: completedEntries)
                        entrySection(title: "Missed", entries: missedEntries)
                        entrySection(title: "Upcoming", entries: futureEntries)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height),
                          abs(value.translation.width) > 60
                    else { return }

                    let offset = value.translation.width < 0 ? 1 : -1
                    Task {
                        guard let day = try? viewModel.selectedDay.addingDays(offset) else {
                            return
                        }
                        await viewModel.daySelected(day)
                    }
                }
        )
        .navigationTitle(dayTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingAddHabit = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Habit 추가")
            }
        }
        .sheet(isPresented: $isShowingAddHabit) {
            AddHabitView { name in
                Task {
                    await viewModel.habitCreated(name: name)
                    isShowingAddHabit = false
                }
            }
        }
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

    private var dayText: String {
        String(
            format: "%04d.%02d.%02d",
            viewModel.selectedDay.year,
            viewModel.selectedDay.month,
            viewModel.selectedDay.day
        )
    }

    private var dayTitle: String {
        guard let today = try? LocalDay(date: Date(), timeZone: .current) else {
            return dayText
        }
        return viewModel.selectedDay == today ? "Today" : dayText
    }

    private var pendingEntries: [HabitEntry] {
        viewModel.entries.filter { $0.state == .pending }
    }

    private var completedEntries: [HabitEntry] {
        viewModel.entries.filter { $0.state == .completed }
    }

    private var missedEntries: [HabitEntry] {
        viewModel.entries.filter { $0.state == .missed }
    }

    private var futureEntries: [HabitEntry] {
        viewModel.entries.filter { $0.state == .future }
    }

    @ViewBuilder
    private func entrySection(title: String?, entries: [HabitEntry]) -> some View {
        if !entries.isEmpty {
            if let title {
                Section(title) { entryRows(entries) }
            } else {
                Section { entryRows(entries) }
            }
        }
    }

    @ViewBuilder
    private func entryRows(_ entries: [HabitEntry]) -> some View {
        ForEach(entries, id: \.habitID) { entry in
            EntryRow(entry: entry) {
                Task {
                    await viewModel.entryTapped(entry)
                }
            }
            .listRowSeparator(.hidden)
        }
    }

}
