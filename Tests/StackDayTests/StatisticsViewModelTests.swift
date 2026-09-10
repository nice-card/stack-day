//
//  StatisticsViewModelTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

@MainActor
struct StatisticsViewModelTests {
    private let now = Date(timeIntervalSince1970: 1_787_212_800)

    @Test("loads active habit summaries")
    func loadsActiveSummaries() async throws {
        let habit = try makeHabit(name: "Read", startedOn: try day(2026, 8, 19))
        let viewModel = makeViewModel(habits: [habit])

        await viewModel.loadSummaries()

        #expect(viewModel.activeSummaries.map(\.id) == [habit.id])
        #expect(viewModel.archivedSummaries.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.alert == nil)
    }

    @Test("separates active and archived habit summaries")
    func separatesActiveAndArchivedSummaries() async throws {
        let activeHabit = try makeHabit(name: "Read", startedOn: try day(2026, 8, 19))
        let archivedHabit = try makeHabit(
            name: "Exercise",
            startedOn: try day(2026, 8, 18),
            endedOn: try day(2026, 8, 19)
        )
        let viewModel = makeViewModel(habits: [activeHabit, archivedHabit])

        await viewModel.loadSummaries()

        #expect(viewModel.activeSummaries.map(\.id) == [activeHabit.id])
        #expect(viewModel.archivedSummaries.map(\.id) == [archivedHabit.id])
    }

    @Test("keeps both summary sections empty when no habits exist")
    func keepsSectionsEmptyWithoutSummaries() async {
        let viewModel = makeViewModel()

        await viewModel.loadSummaries()

        #expect(viewModel.activeSummaries.isEmpty)
        #expect(viewModel.archivedSummaries.isEmpty)
        #expect(viewModel.alert == nil)
    }

    @Test("shows an alert when loading summaries fails")
    func showsAlertWhenLoadingFails() async throws {
        let useCase = LoadStatisticsOverviewUseCase(
            habitRepository: FailingHabitRepository(),
            completionRepository: RecordingCompletionRepository(),
            calculator: HabitStatisticsCalculator(),
            clock: FixedClock(now: now),
            timeZone: .gmt
        )
        let viewModel = StatisticsViewModel(loadStatisticsOverviewUseCase: useCase)

        await viewModel.loadSummaries()

        let alert = try #require(viewModel.alert)
        #expect(alert.title == "Something went wrong")
        #expect(alert.message == "loadFailed")
        #expect(viewModel.isLoading == false)
    }

    private func makeViewModel(habits: [Habit] = []) -> StatisticsViewModel {
        let useCase = LoadStatisticsOverviewUseCase(
            habitRepository: RecordingHabitRepository(habits: habits),
            completionRepository: RecordingCompletionRepository(),
            calculator: HabitStatisticsCalculator(),
            clock: FixedClock(now: now),
            timeZone: .gmt
        )
        return StatisticsViewModel(loadStatisticsOverviewUseCase: useCase)
    }

    private func makeHabit(
        name: String,
        startedOn: LocalDay,
        endedOn: LocalDay? = nil
    ) throws -> Habit {
        try Habit(
            name: name,
            startedOn: startedOn,
            trackingPeriods: [
                try TrackingPeriod(startedOn: startedOn, endedOn: endedOn)
            ],
            createdAt: now
        )
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> LocalDay {
        try LocalDay(year: year, month: month, day: day)
    }
}

private actor FailingHabitRepository: HabitRepository {
    func fetchAll() async throws -> [Habit] {
        throw StatisticsViewModelTestError.loadFailed
    }

    func fetch(id: Habit.ID) async throws -> Habit? {
        nil
    }

    func insert(_ habit: Habit) async throws {}

    func update(_ habit: Habit) async throws {}

    func delete(id: Habit.ID) async throws {}
}

private enum StatisticsViewModelTestError: Error {
    case loadFailed
}
