//
//  DayViewModelTests.swift
//  StackDayTests
//

import Foundation
import Testing
@testable import StackDay

@MainActor
struct DayViewModelTests {
    @Test("loads entries for the selected day")
    func loadsSelectedDayEntries() async throws {
        let selectedDay = try day(2026, 8, 18)
        let habit = try makeHabit(startedOn: selectedDay)
        let viewModel = try await makeViewModel(
            selectedDay: selectedDay,
            habits: [habit]
        )

        await viewModel.viewAppeared()

        #expect(viewModel.selectedDay == selectedDay)
        #expect(viewModel.entries.map(\.targetDay) == [selectedDay])
    }

    @Test("selecting another day reloads its entries")
    func selectingDayReloadsEntries() async throws {
        let initialDay = try day(2026, 8, 18)
        let selectedDay = try day(2026, 8, 19)
        let habit = try makeHabit(startedOn: initialDay)
        let viewModel = try await makeViewModel(
            selectedDay: initialDay,
            habits: [habit]
        )

        await viewModel.daySelected(selectedDay)

        #expect(viewModel.selectedDay == selectedDay)
        #expect(viewModel.entries.map(\.targetDay) == [selectedDay])
    }

    @Test("tapping a pending reference-day entry records completion")
    func tappingPendingReferenceDayEntryRecordsCompletion() async throws {
        let referenceDay = try day(2026, 8, 19)
        let habit = try makeHabit(startedOn: referenceDay)
        let viewModel = try await makeViewModel(
            selectedDay: referenceDay,
            habits: [habit]
        )
        await viewModel.viewAppeared()
        let entry = try #require(viewModel.entries.first)

        await viewModel.entryTapped(entry)

        #expect(viewModel.entries.first?.state == .completed)
    }

    @Test("tapping a missed past-day entry records completion")
    func tappingMissedPastDayEntryRecordsCompletion() async throws {
        let pastDay = try day(2026, 8, 18)
        let habit = try makeHabit(startedOn: pastDay)
        let viewModel = try await makeViewModel(
            selectedDay: pastDay,
            habits: [habit]
        )
        await viewModel.viewAppeared()
        let entry = try #require(viewModel.entries.first)
        #expect(entry.state == .missed)

        await viewModel.entryTapped(entry)

        #expect(viewModel.entries.first?.state == .completed)
    }

    @Test("tapping a completed past-day entry cancels completion")
    func tappingCompletedPastDayEntryCancelsCompletion() async throws {
        let pastDay = try day(2026, 8, 18)
        let habit = try makeHabit(startedOn: pastDay)
        let completion = Completion(
            habitID: habit.id,
            completedOn: pastDay,
            recordedAt: now
        )
        let viewModel = try await makeViewModel(
            selectedDay: pastDay,
            habits: [habit],
            completions: [completion]
        )
        await viewModel.viewAppeared()
        let entry = try #require(viewModel.entries.first)

        await viewModel.entryTapped(entry)

        #expect(viewModel.entries.first?.state == .missed)
    }

    private let now = Date(timeIntervalSince1970: 1_787_126_400)

    private func makeViewModel(
        selectedDay: LocalDay,
        habits: [Habit],
        completions: [Completion] = []
    ) async throws -> DayViewModel {
        let habitRepository = InMemoryHabitRepository()
        let completionRepository = InMemoryCompletionRepository()
        for habit in habits {
            try await habitRepository.insert(habit)
        }
        for completion in completions {
            try await completionRepository.insert(completion)
        }

        let clock = FixedClock(now: try day(2026, 8, 19).startDate(in: .gmt))
        return DayViewModel(
            selectedDay: selectedDay,
            loadDayEntriesUseCase: LoadDayEntriesUseCase(
                habitRepository: habitRepository,
                completionRepository: completionRepository,
                clock: clock,
                timeZone: .gmt
            ),
            recordCompletionUseCase: RecordCompletionUseCase(
                habitRepository: habitRepository,
                completionRepository: completionRepository,
                clock: clock,
                timeZone: .gmt
            ),
            cancelCompletionUseCase: CancelCompletionUseCase(
                habitRepository: habitRepository,
                completionRepository: completionRepository,
                clock: clock,
                timeZone: .gmt
            ),
            createHabitUseCase: CreateHabitUseCase(
                repository: habitRepository,
                clock: clock
            )
        )
    }
    
    @Test("tapping a completed reference-day entry cancels completion")
    func tappingCompletedReferenceDayEntryCancelsCompletion() async throws {
        let referenceDay = try day(2026, 8, 19)
        let habit = try makeHabit(startedOn: referenceDay)
        let completion = Completion(
            habitID: habit.id,
            completedOn: referenceDay,
            recordedAt: now
        )
        let viewModel = try await makeViewModel(
            selectedDay: referenceDay,
            habits: [habit],
            completions: [completion]
        )

        await viewModel.viewAppeared()
        let entry = try #require(viewModel.entries.first)
        #expect(entry.state == .completed)

        await viewModel.entryTapped(entry)

        #expect(viewModel.entries.first?.state == .pending)
    }

    private func makeHabit(startedOn: LocalDay) throws -> Habit {
        try Habit(name: "Read", startedOn: startedOn, createdAt: now)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> LocalDay {
        try LocalDay(year: year, month: month, day: day)
    }
}
