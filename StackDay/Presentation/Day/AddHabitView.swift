import SwiftUI

struct AddHabitView: View {
    @State private var name = ""
    @FocusState private var isNameFocused: Bool
    let add: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 18) {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .accessibilityHidden(true)
                        TextField("Habit name", text: $name)
                            .font(.title2.weight(.medium))
                            .focused($isNameFocused)
                            .submitLabel(.done)
                            .onSubmit { addHabit() }
                            .accessibilityLabel("Habit name")
                    }
                    Divider()
                        .padding(.top, 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture { isNameFocused = false }
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in isNameFocused = false }
            )
            .background(Color(.systemBackground))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: addHabit) {
                            Image(systemName: "checkmark")
                        }
                        .disabled(nameIsEmpty)
                        .accessibilityLabel("Habit 추가")
                    }
                }
                .navigationTitle("Add Habit")
                .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { isNameFocused = true }
    }

    private var nameIsEmpty: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addHabit() {
        guard !nameIsEmpty else { return }
        add(name)
    }
}
