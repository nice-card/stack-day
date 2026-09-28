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
        let viewModel = try makeViewModel(habits: [habit])

        await viewModel.viewAppeared()

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
        let viewModel = try makeViewModel(habits: [activeHabit, archivedHabit])

        await viewModel.viewAppeared()

        #expect(viewModel.activeSummaries.map(\.id) == [activeHabit.id])
        #expect(viewModel.archivedSummaries.map(\.id) == [archivedHabit.id])
    }

    @Test("keeps both summary sections empty when no habits exist")
    func keepsSectionsEmptyWithoutSummaries() async throws {
        let viewModel = try makeViewModel()

        await viewModel.viewAppeared()

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
        let viewModel = StatisticsViewModel(
            loadStatisticsOverviewUseCase: useCase,
            loadHabitStatisticsUseCase: LoadHabitStatisticsUseCase(
                habitRepository: FailingHabitRepository(),
                completionRepository: RecordingCompletionRepository(),
                clock: FixedClock(now: now),
                timeZone: .gmt
            ),
            loadHabitMonthlyCalendarUseCase: LoadHabitMonthlyCalendarUseCase(
                habitRepository: FailingHabitRepository(),
                completionRepository: RecordingCompletionRepository(),
                clock: FixedClock(now: now),
                timeZone: .gmt
            ),
            initialCalendarMonth: try day(2026, 8, 1),
            archiveHabitUseCase: ArchiveHabitUseCase(
                habitRepository: FailingHabitRepository(),
                completionRepository: RecordingCompletionRepository(),
                clock: FixedClock(now: now),
                timeZone: .gmt
            ),
            unarchiveHabitUseCase: UnarchiveHabitUseCase(
                habitRepository: FailingHabitRepository(),
                clock: FixedClock(now: now),
                timeZone: .gmt
            ),
            deleteHabitUseCase: DeleteHabitUseCase(
                habitRepository: FailingHabitRepository(),
                completionRepository: RecordingCompletionRepository()
            )
        )

        await viewModel.viewAppeared()

        let alert = try #require(viewModel.alert)
        #expect(alert.title == "Something went wrong")
        #expect(alert.message == "loadFailed")
        #expect(viewModel.isLoading == false)
    }

    @Test("loads statistics when a habit detail is requested")
    func loadsStatisticsWhenHabitDetailIsRequested() async throws {
        let startDay = try day(2026, 8, 19)
        let habit = try makeHabit(name: "Read", startedOn: startDay)
        let completion = Completion(
            habitID: habit.id,
            completedOn: startDay,
            recordedAt: now
        )
        let viewModel = try makeViewModel(habits: [habit], completions: [completion])

        await viewModel.viewAppeared()
        let summary = try #require(viewModel.activeSummaries.first)
        await viewModel.habitStatisticsDetailRequested(for: summary)

        #expect(
            viewModel.selectedHabitStatistics == HabitStatistics(
                totalCompletedDays: 1,
                eligibleTrackingDays: 2,
                completionRate: 0.5,
                streak: HabitStreak(current: 1, longest: 1)
            )
        )
        #expect(viewModel.alert == nil)
        #expect(viewModel.isLoading == false)

        viewModel.dismissHabitStatisticsDetail()

        #expect(viewModel.selectedHabitStatistics == nil)
    }

    @Test("clears selected statistics and shows an alert when detail loading fails")
    func clearsSelectedStatisticsWhenHabitDetailLoadingFails() async throws {
        let startDay = try day(2026, 8, 19)
        let habit = try makeHabit(name: "Read", startedOn: startDay)
        let viewModel = try makeViewModel(habits: [habit])

        await viewModel.viewAppeared()
        let summary = try #require(viewModel.activeSummaries.first)
        await viewModel.habitStatisticsDetailRequested(for: summary)
        #expect(viewModel.selectedHabitStatistics != nil)

        let missingSummary = HabitStatisticsSummary(
            id: Habit.ID(),
            name: "Missing",
            isArchived: false,
            currentStreak: 0,
            completionRate: 0
        )
        await viewModel.habitStatisticsDetailRequested(for: missingSummary)

        #expect(viewModel.selectedHabitStatistics == nil)
        _ = try #require(viewModel.alert)
        #expect(viewModel.isLoading == false)
    }

    @Test("archiving, unarchiving, and deleting a habit refreshes its summaries")
    func lifecycleActionsRefreshSummaries() async throws {
        let habit = try makeHabit(name: "Read", startedOn: try day(2026, 8, 19))
        let viewModel = try await makeLifecycleViewModel(habits: [habit])

        await viewModel.viewAppeared()
        let archived = await viewModel.habitArchived(habitID: habit.id)

        #expect(archived)
        #expect(viewModel.activeSummaries.isEmpty)
        #expect(viewModel.archivedSummaries.map(\.id) == [habit.id])

        let unarchived = await viewModel.habitUnarchived(habitID: habit.id)

        #expect(unarchived)
        #expect(viewModel.activeSummaries.map(\.id) == [habit.id])
        #expect(viewModel.archivedSummaries.isEmpty)

        let deleted = await viewModel.habitDeleted(habitID: habit.id)

        #expect(deleted)
        #expect(viewModel.activeSummaries.isEmpty)
        #expect(viewModel.archivedSummaries.isEmpty)
    }

    private func makeViewModel(
        habits: [Habit] = [],
        completions: [Completion] = []
    ) throws -> StatisticsViewModel {
        let habitRepository = RecordingHabitRepository(habits: habits)
        let completionRepository = RecordingCompletionRepository(completions: completions)
        return try makeViewModel(
            habitRepository: habitRepository,
            completionRepository: completionRepository
        )
    }

    private func makeLifecycleViewModel(habits: [Habit]) async throws -> StatisticsViewModel {
        let habitRepository = InMemoryHabitRepository()
        let completionRepository = InMemoryCompletionRepository()
        for habit in habits {
            try await habitRepository.insert(habit)
        }
        return try makeViewModel(
            habitRepository: habitRepository,
            completionRepository: completionRepository
        )
    }

    private func makeViewModel(
        habitRepository: any HabitRepository,
        completionRepository: any CompletionRepository
    ) throws -> StatisticsViewModel {
        let overviewUseCase = LoadStatisticsOverviewUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            calculator: HabitStatisticsCalculator(),
            clock: FixedClock(now: now),
            timeZone: .gmt
        )
        let detailUseCase = LoadHabitStatisticsUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            clock: FixedClock(now: now),
            timeZone: .gmt
        )
        let calendarUseCase = LoadHabitMonthlyCalendarUseCase(
            habitRepository: habitRepository,
            completionRepository: completionRepository,
            clock: FixedClock(now: now),
            timeZone: .gmt
        )
        return StatisticsViewModel(
            loadStatisticsOverviewUseCase: overviewUseCase,
            loadHabitStatisticsUseCase: detailUseCase,
            loadHabitMonthlyCalendarUseCase: calendarUseCase,
            initialCalendarMonth: try day(2026, 8, 1),
            archiveHabitUseCase: ArchiveHabitUseCase(
                habitRepository: habitRepository,
                completionRepository: completionRepository,
                clock: FixedClock(now: now),
                timeZone: .gmt
            ),
            unarchiveHabitUseCase: UnarchiveHabitUseCase(
                habitRepository: habitRepository,
                clock: FixedClock(now: now),
                timeZone: .gmt
            ),
            deleteHabitUseCase: DeleteHabitUseCase(
                habitRepository: habitRepository,
                completionRepository: completionRepository
            )
        )
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
