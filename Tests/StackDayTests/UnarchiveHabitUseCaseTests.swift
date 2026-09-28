import Foundation
import Testing
@testable import StackDay

struct UnarchiveHabitUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_086_400)

    @Test("reopens a period when unarchived on the archive day")
    func reopensSameDayPeriodWithoutAddingHistory() async throws {
        let day = try LocalDay(date: now, timeZone: .gmt)
        var habit = try Habit(name: "Read", startedOn: day, createdAt: now)
        try habit.archive(on: day, effectiveArchivedOn: day, updatedAt: now)
        let repository = RecordingHabitRepository(habits: [habit])
        let useCase = UnarchiveHabitUseCase(
            habitRepository: repository,
            clock: FixedClock(now: now),
            timeZone: .gmt
        )

        let restored = try await useCase.execute(habitID: habit.id)

        #expect(restored.trackingPeriods.count == 1)
        #expect(restored.trackingPeriods.first?.endedOn == nil)
        #expect(restored.isTracked(on: day))
    }
}
