import Foundation
import Testing
@testable import StackDay

struct FileCompletionRepositoryTests {
    private let fileManager = FileManager.default
    private let recordedAt = Date(timeIntervalSince1970: 1_000_000)

    @Test("a missing completions file produces an empty repository")
    func missingFileProducesEmptyRepository() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: directoryURL) }
        let repository = makeRepository(directoryURL: directoryURL)

        #expect(try await repository.fetchAll(for: Habit.ID()).isEmpty)
    }

    @Test("a new repository restores completion changes and habit deletion cleanup")
    func restoresCompletionChanges() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: directoryURL) }
        let habitID = Habit.ID()
        let otherHabitID = Habit.ID()
        let firstDay = try LocalDay(year: 2026, month: 8, day: 1)
        let secondDay = try firstDay.addingDays(1)
        let first = Completion(habitID: habitID, completedOn: firstDay, recordedAt: recordedAt)
        let canceled = Completion(habitID: habitID, completedOn: secondDay, recordedAt: recordedAt)
        let retained = Completion(habitID: otherHabitID, completedOn: firstDay, recordedAt: recordedAt)

        let repository = makeRepository(directoryURL: directoryURL)
        try await repository.insert(first)
        try await repository.insert(canceled)
        try await repository.insert(retained)
        try await repository.delete(id: canceled.id)
        #expect(try await makeRepository(directoryURL: directoryURL).fetchAll(for: habitID) == [first])

        try await repository.deleteAll(for: habitID)
        let restoredRepository = makeRepository(directoryURL: directoryURL)
        #expect(try await restoredRepository.fetchAll(for: habitID).isEmpty)
        #expect(try await restoredRepository.fetchAll(for: otherHabitID) == [retained])
    }

    @Test("a duplicate completion cannot be recorded for the same habit and day")
    func rejectsDuplicateCompletionDayAfterRestore() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: directoryURL) }
        let habitID = Habit.ID()
        let day = try LocalDay(year: 2026, month: 8, day: 1)
        let completion = Completion(habitID: habitID, completedOn: day, recordedAt: recordedAt)
        let duplicate = Completion(
            habitID: habitID,
            completedOn: day,
            recordedAt: recordedAt.addingTimeInterval(1)
        )

        try await makeRepository(directoryURL: directoryURL).insert(completion)

        await #expect(throws: CompletionRepositoryError.alreadyExists) {
            try await makeRepository(directoryURL: directoryURL).insert(duplicate)
        }
    }

    @Test("corrupted completions JSON produces an error without modifying the file")
    func corruptedJSONDoesNotModifyFile() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: directoryURL) }
        let fileURL = directoryURL.appendingPathComponent("completions.json")
        let corruptedData = Data("not valid JSON".utf8)
        try corruptedData.write(to: fileURL)
        let completion = Completion(
            habitID: Habit.ID(),
            completedOn: try LocalDay(year: 2026, month: 8, day: 1),
            recordedAt: recordedAt
        )

        let repository = makeRepository(directoryURL: directoryURL)

        await #expect(throws: (any Error).self) {
            try await repository.insert(completion)
        }
        #expect(try Data(contentsOf: fileURL) == corruptedData)
    }

    private func makeRepository(directoryURL: URL) -> FileCompletionRepository {
        FileCompletionRepository(
            directoryURL: directoryURL,
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            fileManager: FileManager()
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("FileCompletionRepositoryTests-\(UUID().uuidString)")
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }
}
