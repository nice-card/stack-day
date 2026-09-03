//
//  DayViewModel.swift
//  StackDay
//

import Observation

@MainActor
@Observable
final class DayViewModel {
    private let loadDayEntriesUseCase: LoadDayEntriesUseCase
    private let recordCompletionUseCase: RecordCompletionUseCase
    private let cancelCompletionUseCase: CancelCompletionUseCase
    private let createHabitUseCase: CreateHabitUseCase
    private let loadHabitDetailUseCase: LoadHabitDetailUseCase
    private let renameHabitUseCase: RenameHabitUseCase
    private(set) var selectedDay: LocalDay
    private(set) var entries: [HabitEntry] = []
    private(set) var isLoading = false
    private(set) var alert: DayAlert?
    private(set) var selectedHabit: Habit?

    init(
        selectedDay: LocalDay,
        loadDayEntriesUseCase: LoadDayEntriesUseCase,
        recordCompletionUseCase: RecordCompletionUseCase,
        cancelCompletionUseCase: CancelCompletionUseCase,
        createHabitUseCase: CreateHabitUseCase,
        loadHabitDetailUseCase: LoadHabitDetailUseCase,
        renameHabitUseCase: RenameHabitUseCase
    ) {
        self.selectedDay = selectedDay
        self.loadDayEntriesUseCase = loadDayEntriesUseCase
        self.recordCompletionUseCase = recordCompletionUseCase
        self.cancelCompletionUseCase = cancelCompletionUseCase
        self.createHabitUseCase = createHabitUseCase
        self.loadHabitDetailUseCase = loadHabitDetailUseCase
        self.renameHabitUseCase = renameHabitUseCase
    }

    func viewAppeared() async {
        await perform {
            try await self.loadEntries()
        }
    }

    func daySelected(_ day: LocalDay) async {
        await perform {
            self.selectedDay = day
            try await self.loadEntries()
        }
    }

    func entryTapped(_ entry: HabitEntry) async {
        await perform {
            switch entry.state {
            case .pending, .missed:
                try await self.recordCompletionUseCase.execute(
                    habitID: entry.habitID,
                    completedOn: entry.targetDay
                )
            case .completed:
                try await self.cancelCompletionUseCase.execute(
                    habitID: entry.habitID,
                    completedOn: entry.targetDay
                )
            case .future:
                return
            }
            try await self.loadEntries()
        }
    }

    func habitCreated(name: String) async {
        await perform {
            try await self.createHabitUseCase.execute(name: name, startedOn: self.selectedDay)
            try await self.loadEntries()
        }
    }

    func habitDetailRequested(for entry: HabitEntry) async {
        await perform {
            self.selectedHabit = try await self.loadHabitDetailUseCase.execute(id: entry.habitID)
        }
    }

    func habitRenamed(habitID: Habit.ID, name: String) async {
        await perform {
            self.selectedHabit = try await self.renameHabitUseCase.execute(
                habitID: habitID,
                name: name
            )
            try await self.loadEntries()
        }
    }

    func dismissHabitDetail() {
        selectedHabit = nil
    }
    private func perform(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await operation()
        } catch {
            alert = .operationFailed(String(describing: error))
        }
    }

    func dismissAlert() {
        alert = nil
    }

    private func loadEntries() async throws {
        entries = try await loadDayEntriesUseCase.execute(on: selectedDay)
    }
}

enum DayAlert: Identifiable {
    case operationFailed(String)

    var id: String {
        switch self {
        case .operationFailed(let message): message
        }
    }
    var title: String {
        switch self {
        case .operationFailed: "Something went wrong"
        }
    }
    var message: String {
        switch self {
        case .operationFailed(let message): message
        }
    }
}
