//
//  HabitMonthlyCalendarView.swift
//  StackDay
//

import SwiftUI

struct HabitMonthlyCalendarView: View {
    let calendarMonth: HabitMonthlyCalendar
    let isMonthNavigationDisabled: Bool
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onPreviousMonth) {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Previous month")
                .disabled(isMonthNavigationDisabled)
                Spacer()
                Text(verbatim: "\(calendarMonth.month).\(calendarMonth.year)")
                    .font(.headline)
                Spacer()
                Button(action: onNextMonth) {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel("Next month")
                .disabled(
                    isMonthNavigationDisabled ||
                        !calendarMonth.canMoveToNextMonth
                )
            }

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    ForEach(weekdaySymbols.indices, id: \.self) { index in
                        Text(weekdaySymbols[index])
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                ForEach(calendarGridRows.indices, id: \.self) { rowIndex in
                    GridRow {
                        ForEach(calendarGridRows[rowIndex].indices, id: \.self) { columnIndex in
                            if let day = calendarGridRows[rowIndex][columnIndex] {
                                CalendarDayCell(day: day)
                            } else {
                                Color.clear
                                    .frame(height: 40)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstIndex = calendar.firstWeekday - 1
        return Array(symbols[firstIndex...] + symbols[..<firstIndex])
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.timeZone = .gmt
        return calendar
    }

    private var leadingPlaceholderCount: Int {
        var components = DateComponents()
        components.year = calendarMonth.year
        components.month = calendarMonth.month
        components.day = 1
        guard let firstDay = calendar.date(from: components) else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDay)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private var calendarGridRows: [[HabitMonthlyCalendarDay?]] {
        var cells = Array(
            repeating: HabitMonthlyCalendarDay?.none,
            count: leadingPlaceholderCount
        )
        cells.append(contentsOf: calendarMonth.days.map(Optional.some))

        let trailingPlaceholderCount = (7 - cells.count % 7) % 7
        cells.append(
            contentsOf: Array(
                repeating: HabitMonthlyCalendarDay?.none,
                count: trailingPlaceholderCount
            )
        )

        return stride(from: 0, to: cells.count, by: 7).map { startIndex in
            Array(cells[startIndex..<(startIndex + 7)])
        }
    }
}

private struct CalendarDayCell: View {
    let day: HabitMonthlyCalendarDay

    var body: some View {
        Text("\(day.date.day)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foregroundStyle)
            .frame(width: 36, height: 36)
            .background {
                Circle()
                    .fill(backgroundColor)
            }
            .overlay {
                if day.isToday {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
    }

    private var backgroundColor: Color {
        switch day.state {
        case .completed: .green
        case .missed: .orange
        case .pending, .empty: .clear
        }
    }

    private var foregroundStyle: Color {
        switch day.state {
        case .completed, .missed: .white
        case .pending: .accentColor
        case .empty: .secondary
        }
    }

    private var accessibilityLabel: String {
        let stateLabel: String
        switch day.state {
        case .completed: stateLabel = "completed"
        case .missed: stateLabel = "missed"
        case .pending: stateLabel = "pending"
        case .empty: stateLabel = "no completion state"
        }
        let todayLabel = day.isToday ? ", today" : ""
        return "\(day.date.year)-\(day.date.month)-\(day.date.day), \(stateLabel)\(todayLabel)"
    }
}
