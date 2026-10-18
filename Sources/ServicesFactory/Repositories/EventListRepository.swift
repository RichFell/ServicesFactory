//
//  EventListRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A repository that retrieves list models from a data source.
protocol EventListRepository: Sendable {
    /// Streams all available lists.
    ///
    /// Yields the current lists on subscription, then again whenever they change if the source
    /// supports it. The stream finishes with an error if the lists cannot be retrieved.
    func allLists() -> AsyncThrowingStream<[List], any Error>

    /// Streams all available events, with their lists resolved.
    ///
    /// Yields the current events on subscription, then again whenever they change if the source
    /// supports it. The stream finishes with an error if the events cannot be retrieved.
    func allEvents() -> AsyncThrowingStream<[Event], any Error>

    /// Streams all event runs, each with its own list snapshot and completed items.
    ///
    /// Yields the current runs on subscription, then again whenever they change if the source
    /// supports it. The stream finishes with an error if the runs cannot be retrieved.
    func allEventRuns() -> AsyncThrowingStream<[EventRun], any Error>
}
