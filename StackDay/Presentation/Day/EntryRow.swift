import SwiftUI

struct EntryRow: View {
    let entry: HabitEntry
    let onCompletionTap: () -> Void
    let onDetailTap: () -> Void

    var body: some View {
        Button(action: onDetailTap) {
            HStack {
                Color.clear
                    .frame(width: 44, height: 44)
                Text(entry.habitName)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.habitName) details")
        .overlay(alignment: .leading) {
            Button(action: onCompletionTap) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(entry.state == .future || !entry.isTracked)
        }
    }

    private var stateLabel: String {
        switch entry.state {
        case .pending: "Pending"
        case .completed: "Completed"
        case .missed: "Missed"
        case .future: "Upcoming"
        }
    }

    private var iconName: String {
        switch entry.state {
        case .pending: "circle"
        case .completed: "checkmark.circle.fill"
        case .missed: "xmark.circle"
        case .future: "calendar"
        }
    }

    private var color: Color {
        switch entry.state {
        case .pending: .secondary
        case .completed: .green
        case .missed: .orange
        case .future: .secondary
        }
    }
}
