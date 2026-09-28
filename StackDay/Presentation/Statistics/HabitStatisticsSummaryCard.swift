//
//  HabitStatisticsSummaryCard.swift
//  StackDay
//
//  Created by Kelly Dev on 9/10/26.
//

import SwiftUI

struct HabitStatisticsSummaryCard: View {
    let summary: HabitStatisticsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(summary.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                statistic(
                    title: "Current streak",
                    value: "\(summary.currentStreak) days"
                )
                statistic(
                    title: "Completion rate",
                    value: summary.completionRate.formatted(
                        .percent.precision(.fractionLength(0))
                    )
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func statistic(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
