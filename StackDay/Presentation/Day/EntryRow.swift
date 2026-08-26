import SwiftUI

struct EntryRow: View {
    let entry: HabitEntry
    let onTap: () -> Void

    var body: some View {
        HStack {
            Button(action: onTap) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(entry.state == .future)
            Text(entry.habitName)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.habitName), \(stateLabel)")
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
