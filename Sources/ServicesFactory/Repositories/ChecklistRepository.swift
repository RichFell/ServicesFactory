//
//  ChecklistRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A repository that retrieves checklist models from a data source.
protocol ChecklistRepository: Sendable {
    /// Streams all available checklists.
    ///
    /// Yields the current checklists on subscription, then again whenever they change if the source
    /// supports it. The stream finishes with an error if the checklists cannot be retrieved.
    func allChecklists() -> AsyncThrowingStream<[Checklist], any Error>
}
