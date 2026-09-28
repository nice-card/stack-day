import SwiftUI

struct AddHabitView: View {
    @State private var name = ""
    let add: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form { TextField("Habit 이름", text: $name) }
                .navigationTitle("Habit 추가")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("추가") { add(name) }
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
        .presentationDetents([.medium])
    }
}
