//
//  HabitDetailView.swift
//  StackDay
//

import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    let completionState: HabitEntry.State
    let onCompletionTap: () -> Void
    let onNameSubmit: (String) -> Void
    
    @State private var isEditingName = false
    @State private var editedName: String
    @FocusState private var isNameFieldFocused: Bool

    init(
        habit: Habit,
        completionState: HabitEntry.State,
        onCompletionTap: @escaping () -> Void,
        onNameSubmit: @escaping (String) -> Void
    ) {
        self.habit = habit
        self.completionState = completionState
        self.onCompletionTap = onCompletionTap
        self.onNameSubmit = onNameSubmit
        _editedName = State(initialValue: habit.name)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    habitHeader
                    Divider()
                        .padding(.top, 28)
                    detailRow(
                        icon: "calendar",
                        title: "Tracking period",
                        value: trackingPeriod
                    )
                    Divider()
                    detailRow(
                        icon: "arrow.trianglehead.2.clockwise.rotate.90",
                        title: "Repeat",
                        value: "매일"
                    )
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var habitHeader: some View {
        HStack(alignment: .center, spacing: 18) {
            Button(action: onCompletionTap) {
                Image(systemName: completionIconName)
                    .font(.title2)
                    .foregroundStyle(completionColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(completionState == .future)
            .accessibilityLabel("Toggle completion")
            TextField("Habit name", text: $editedName)
                .font(.title2.weight(.medium))
                .focused($isNameFieldFocused)
                .submitLabel(.done)
                .onSubmit { saveEditedName() }
                .accessibilityLabel("Habit name")
        }
    }

    private var trackingPeriod: String {
        guard !habit.trackingPeriods.isEmpty else {
            return "No tracking days"
        }

        return habit.trackingPeriods
            .map { "\(formatted($0.startedOn)) - \($0.endedOn.map(formatted) ?? "Present")" }
            .joined(separator: ", ")
    }

    private func formatted(_ day: LocalDay) -> String {
        String(format: "%04d.%02d.%02d", day.year, day.month, day.day)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 18)
    }

    private var completionIconName: String {
        switch completionState {
        case .pending: "circle"
        case .completed: "checkmark.circle.fill"
        case .missed: "xmark.circle"
        case .future: "calendar"
        }
    }

    private var completionColor: Color {
        switch completionState {
        case .pending, .future: .secondary
        case .completed: .green
        case .missed: .orange
        }
    }

    private func saveEditedName() {
        onNameSubmit(editedName)
        isNameFieldFocused = false
        isEditingName = false
    }

    private func cancelEditingName() {
        editedName = habit.name
        isNameFieldFocused = false
        isEditingName = false
    }
}
