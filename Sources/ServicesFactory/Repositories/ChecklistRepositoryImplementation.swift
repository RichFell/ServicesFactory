//
//  ChecklistRepositoryImplementation.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation

/// The default ``ChecklistRepository`` implementation.
///
/// Retrieves raw checklist data from an injected data source and uses its
/// ``ChecklistBuilder`` to decode that data into ``Checklist`` models.
final class ChecklistRepositoryImplementation: ChecklistRepository {
    private let builder: ChecklistBuilder
    private let fetchData: @Sendable () async throws -> Data

    init(
        builder: ChecklistBuilder = ChecklistBuilder(),
        fetchData: @escaping @Sendable () async throws -> Data
    ) {
        self.builder = builder
        self.fetchData = fetchData
    }

    /// Yields the decoded checklists once, then finishes. The raw data source does not report changes.
    func allChecklists() -> AsyncThrowingStream<[Checklist], any Error> {
        let builder = builder
        let fetchData = fetchData
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    continuation.yield(try builder.decode(try await fetchData()))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
