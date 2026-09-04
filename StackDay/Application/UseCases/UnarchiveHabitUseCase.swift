import Foundation

struct UnarchiveHabitUseCase {
    private let habitRepository: any HabitRepository
    private let clock: any Clock
    private let timeZone: TimeZone

    init(habitRepository: any HabitRepository, clock: any Clock, timeZone: TimeZone) {
        self.habitRepository = habitRepository
        self.clock = clock
        self.timeZone = timeZone
    }

    func execute(habitID: Habit.ID) async throws -> Habit {
        guard var habit = try await habitRepository.fetch(id: habitID) else {
            throw UnarchiveHabitError.habitNotFound
        }
        try habit.unarchive(
            on: LocalDay(date: clock.now, timeZone: timeZone),
            updatedAt: clock.now
        )
        try await habitRepository.update(habit)
        return habit
    }
}

enum UnarchiveHabitError: Error, Equatable {
    case habitNotFound
}
