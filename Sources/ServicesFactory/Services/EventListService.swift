//
//  EventListService.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A service that retrieves and edits lists, their items, and events.
///
/// Items are standalone and can be shared by several lists. Deleting a list or removing an item
/// from a list never deletes the item; only ``deleteItem(identifier:)`` does.
public protocol EventListService: Service {
    /// Streams all available lists.
    ///
    /// Each subscription immediately receives the current lists, then a new value after every
    /// change made through this service. The stream finishes with an error if loading fails.
    func allLists() -> AsyncThrowingStream<[List], any Error>

    /// Streams all available events.
    ///
    /// Each subscription immediately receives the current events, then a new value after every
    /// change made through this service. The stream finishes with an error if loading fails.
    func allEvents() -> AsyncThrowingStream<[Event], any Error>

    /// Creates a list with its fields and items.
    ///
    /// Items whose identifier already exists are linked to the new list instead of duplicated.
    /// - Parameter list: The list to create.
    func createList(_ list: List) async throws

    /// Updates a list's title and fields. Its items are managed with the item functions.
    ///
    /// - Parameter list: The list carrying the new title and fields.
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when the list does not exist.
    func updateList(_ list: List) async throws

    /// Deletes a list and removes it from any event. Its items are kept for reuse in other lists.
    ///
    /// - Parameter identifier: The identifier of the list to delete. Does nothing if it does not exist.
    func deleteList(identifier: String) async throws

    /// Adds an item to the end of a list, creating the item if it is new or updating it if it exists.
    ///
    /// - Parameters:
    ///   - item: The item to add.
    ///   - listIdentifier: The identifier of the list to add it to.
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when the list does not exist.
    func addItem(_ item: ListItem, toListWithIdentifier listIdentifier: String) async throws

    /// Removes an item from a list. The item is kept and stays in its other lists.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the item to remove.
    ///   - listIdentifier: The identifier of the list to remove it from.
    func removeItem(identifier: String, fromListWithIdentifier listIdentifier: String) async throws

    /// Updates an item everywhere it appears.
    ///
    /// - Parameter item: The item carrying the new name and weight.
    /// - Throws: ``EventListError/itemNotFound(identifier:)`` when the item does not exist.
    func updateItem(_ item: ListItem) async throws

    /// Deletes an item from every list. Runs keep their own copy, so past runs still show it.
    ///
    /// - Parameter identifier: The identifier of the item to delete. Does nothing if it does not exist.
    func deleteItem(identifier: String) async throws

    /// Moves an item to a new position within a list.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the item to move.
    ///   - listIdentifier: The identifier of the list containing the item.
    ///   - position: The new zero-based index, clamped to the list's bounds.
    /// - Throws: ``EventListError/listNotFound(identifier:)`` or
    ///   ``EventListError/itemNotFound(identifier:)`` when either does not exist.
    func moveItem(identifier: String, inListWithIdentifier listIdentifier: String, to position: Int) async throws

    /// Streams all event runs, each with its own snapshot of the lists as they were when it started.
    ///
    /// Each subscription immediately receives the current runs, then a new value after every
    /// change made through this service. The stream finishes with an error if loading fails.
    func allEventRuns() -> AsyncThrowingStream<[EventRun], any Error>

    /// Creates an event that uses the already existing lists named by `event.lists`, in order.
    ///
    /// - Parameter event: The event to create.
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when a list does not exist.
    func createEvent(_ event: Event) async throws

    /// Updates an event's title and lists. Runs already started are not affected.
    ///
    /// - Parameter event: The event carrying the new title and lists.
    /// - Throws: ``EventListError/eventNotFound(identifier:)`` or ``EventListError/listNotFound(identifier:)``.
    func updateEvent(_ event: Event) async throws

    /// Deletes an event and all of its runs. Its lists are kept.
    ///
    /// - Parameter identifier: The identifier of the event to delete. Does nothing if it does not exist.
    func deleteEvent(identifier: String) async throws

    /// Starts a new run of an event, snapshotting its lists, fields and items as they are now.
    ///
    /// - Parameter eventIdentifier: The identifier of the event to run.
    /// - Returns: The new run, with nothing completed.
    /// - Throws: ``EventListError/eventNotFound(identifier:)`` when the event does not exist.
    func startRun(ofEventWithIdentifier eventIdentifier: String) async throws -> EventRun

    /// Marks an item of a run as completed or not completed.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the item in the run's snapshot.
    ///   - isCompleted: Whether the item is completed.
    ///   - runIdentifier: The identifier of the run.
    /// - Throws: ``EventListError/runNotFound(identifier:)`` or
    ///   ``EventListError/itemNotFound(identifier:)`` when the item is not in the run.
    func setItem(
        identifier: String,
        isCompleted: Bool,
        inRunWithIdentifier runIdentifier: String
    ) async throws

    /// Marks a run as completed, or reopens it.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the run.
    ///   - isComplete: Whether the run is completed. Completing records the completion date.
    /// - Throws: ``EventListError/runNotFound(identifier:)`` when the run does not exist.
    func setRun(identifier: String, isComplete: Bool) async throws

    /// Deletes a run and its snapshot. The event and its lists are kept.
    ///
    /// - Parameter identifier: The identifier of the run to delete. Does nothing if it does not exist.
    func deleteRun(identifier: String) async throws
}
