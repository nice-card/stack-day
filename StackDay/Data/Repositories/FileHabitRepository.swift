//
//  FileHabitRepository.swift
//  StackDay
//

import Foundation

actor FileHabitRepository: HabitRepository {
    private let directoryURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(
        directoryURL: URL,
        encoder: JSONEncoder,
        decoder: JSONDecoder,
        fileManager: FileManager
    ) {
        self.directoryURL = directoryURL
        self.encoder = encoder
        self.decoder = decoder
        self.fileManager = fileManager
    }

    func fetchAll() async throws -> [Habit] {
        try readHabits()
    }

    func fetch(id: Habit.ID) async throws -> Habit? {
        try readHabits().first { $0.id == id }
    }

    func insert(_ habit: Habit) async throws {
        var habits = try readHabits()
        guard !habits.contains(where: { $0.id == habit.id }) else {
            throw HabitRepositoryError.alreadyExists
        }
        habits.append(habit)
        try write(habits)
    }

    func update(_ habit: Habit) async throws {
        var habits = try readHabits()
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else {
            throw HabitRepositoryError.notFound
        }
        habits[index] = habit
        try write(habits)
    }

    func delete(id: Habit.ID) async throws {
        var habits = try readHabits()
        guard let index = habits.firstIndex(where: { $0.id == id }) else {
            throw HabitRepositoryError.notFound
        }
        habits.remove(at: index)
        try write(habits)
    }

    private var fileURL: URL {
        directoryURL.appendingPathComponent("habits.json")
    }

    private func readHabits() throws -> [Habit] {
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([HabitDTO].self, from: data).map { try $0.toDomain() }
    }

    private func write(_ habits: [Habit]) throws {
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(habits.map(HabitDTO.init))
        let temporaryURL = directoryURL.appendingPathComponent(
            ".habits-\(UUID().uuidString).tmp"
        )
        try data.write(to: temporaryURL)

        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                _ = try fileManager.replaceItemAt(
                    fileURL,
                    withItemAt: temporaryURL,
                    backupItemName: nil,
                    options: []
                )
            } else {
                try fileManager.moveItem(at: temporaryURL, to: fileURL)
            }
        } catch {
            try? fileManager.removeItem(at: temporaryURL)
            throw error
        }
    }
}
