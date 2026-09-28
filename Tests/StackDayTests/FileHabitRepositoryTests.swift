import Foundation
import Testing
@testable import StackDay

struct FileHabitRepositoryTests {
    private let fileManager = FileManager.default
    private let createdAt = Date(timeIntervalSince1970: 1_000_000)

    @Test("a missing habits file produces an empty repository")
    func missingFileProducesEmptyRepository() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: directoryURL) }

        let repository = makeRepository(directoryURL: directoryURL)

        #expect(try await repository.fetchAll().isEmpty)
    }

    @Test("a new repository restores a habit through lifecycle changes")
    func restoresHabitAfterLifecycleChanges() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: directoryURL) }
        let startedOn = try LocalDay(year: 2026, month: 8, day: 1)
        let archiveDay = try startedOn.addingDays(2)
        let unarchiveDay = try archiveDay.addingDays(2)
        let habit = try Habit(name: "Read", startedOn: startedOn, createdAt: createdAt)

        let repository = makeRepository(directoryURL: directoryURL)
        try await repository.insert(habit)
        var renamedHabit = habit
        try renamedHabit.rename(to: "Read Books", updatedAt: createdAt.addingTimeInterval(1))
        try await repository.update(renamedHabit)
        #expect(try await makeRepository(directoryURL: directoryURL).fetch(id: habit.id) == renamedHabit)

        var archivedHabit = renamedHabit
        try archivedHabit.archive(
            on: archiveDay,
            effectiveArchivedOn: archiveDay,
            updatedAt: createdAt.addingTimeInterval(2)
        )
        try await repository.update(archivedHabit)
        #expect(try await makeRepository(directoryURL: directoryURL).fetch(id: habit.id) == archivedHabit)

        var unarchivedHabit = archivedHabit
        try unarchivedHabit.unarchive(
            on: unarchiveDay,
            updatedAt: createdAt.addingTimeInterval(3)
        )
        try await repository.update(unarchivedHabit)
        #expect(try await makeRepository(directoryURL: directoryURL).fetch(id: habit.id) == unarchivedHabit)

        try await repository.delete(id: habit.id)
        #expect(try await makeRepository(directoryURL: directoryURL).fetchAll().isEmpty)
    }

    @Test("corrupted habits JSON produces an error without modifying the file")
    func corruptedJSONDoesNotModifyFile() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: directoryURL) }
        let fileURL = directoryURL.appendingPathComponent("habits.json")
        let corruptedData = Data("not valid JSON".utf8)
        try corruptedData.write(to: fileURL)
        let habit = try Habit(
            name: "Read",
            startedOn: LocalDay(year: 2026, month: 8, day: 1),
            createdAt: createdAt
        )

        let repository = makeRepository(directoryURL: directoryURL)

        await #expect(throws: (any Error).self) {
            try await repository.insert(habit)
        }
        #expect(try Data(contentsOf: fileURL) == corruptedData)
    }

    private func makeRepository(directoryURL: URL) -> FileHabitRepository {
        FileHabitRepository(
            directoryURL: directoryURL,
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            fileManager: FileManager()
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("FileHabitRepositoryTests-\(UUID().uuidString)")
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }
}
