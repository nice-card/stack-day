//
//  FileCompletionRepository.swift
//  StackDay
//

import Foundation

actor FileCompletionRepository: CompletionRepository {
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

    func fetchAll(for habitID: Habit.ID) async throws -> [Completion] {
        try readCompletions().filter { $0.habitID == habitID }
    }

    func fetch(habitID: Habit.ID, completedOn day: LocalDay) async throws -> Completion? {
        try readCompletions().first {
            $0.habitID == habitID && $0.completedOn == day
        }
    }

    func insert(_ completion: Completion) async throws {
        var completions = try readCompletions()
        guard !completions.contains(where: { $0.id == completion.id }) else {
            throw CompletionRepositoryError.alreadyExists
        }
        guard !completions.contains(where: {
            $0.habitID == completion.habitID && $0.completedOn == completion.completedOn
        }) else {
            throw CompletionRepositoryError.alreadyExists
        }
        completions.append(completion)
        try write(completions)
    }

    func delete(id completionID: Completion.ID) async throws {
        var completions = try readCompletions()
        guard let index = completions.firstIndex(where: { $0.id == completionID }) else {
            throw CompletionRepositoryError.notFound
        }
        completions.remove(at: index)
        try write(completions)
    }

    func deleteAll(for habitID: Habit.ID) async throws {
        let completions = try readCompletions().filter { $0.habitID != habitID }
        try write(completions)
    }

    private var fileURL: URL {
        directoryURL.appendingPathComponent("completions.json")
    }

    private func readCompletions() throws -> [Completion] {
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([CompletionDTO].self, from: data).map { $0.toDomain() }
    }

    private func write(_ completions: [Completion]) throws {
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(completions.map(CompletionDTO.init))
        let temporaryURL = directoryURL.appendingPathComponent(
            ".completions-\(UUID().uuidString).tmp"
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
