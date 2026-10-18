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

    /// Creates a list with its fields, sections and items.
    ///
    /// Items whose identifier already exists are linked to the new list instead of duplicated.
    /// - Parameter list: The list to create.
    func createList(_ list: List) async throws

    /// Updates a list's title and fields. Its sections and items are managed with their own functions.
    ///
    /// - Parameter list: The list carrying the new title and fields.
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when the list does not exist.
    func updateList(_ list: List) async throws

    /// Deletes a list and removes it from any event. Its items are kept for reuse in other lists. Runs keep their own copy.
    ///
    /// - Parameter identifier: The identifier of the list to delete. Does nothing if it does not exist.
    func deleteList(identifier: String) async throws

    /// Adds a section, with its items, to the end of a list. Existing items are linked, not duplicated.
    ///
    /// - Parameters:
    ///   - section: The section to add.
    ///   - listIdentifier: The identifier of the list to add it to.
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when the list does not exist.
    func addSection(_ section: ListSection, toListWithIdentifier listIdentifier: String) async throws

    /// Updates a section's title. Its items are managed with the item functions.
    ///
    /// - Parameter section: The section carrying the new title.
    /// - Throws: ``EventListError/sectionNotFound(identifier:)`` when the section does not exist.
    func updateSection(_ section: ListSection) async throws

    /// Deletes a section. Its items are kept for reuse in other sections.
    ///
    /// - Parameter identifier: The identifier of the section to delete. Does nothing if it does not exist.
    func deleteSection(identifier: String) async throws

    /// Adds an item to the end of a section, creating the item if it is new or updating it if it exists.
    ///
    /// - Parameters:
    ///   - item: The item to add.
    ///   - sectionIdentifier: The identifier of the section to add it to.
    /// - Throws: ``EventListError/sectionNotFound(identifier:)`` when the section does not exist.
    func addItem(_ item: ListItem, toSectionWithIdentifier sectionIdentifier: String) async throws

    /// Removes an item from a section. The item is kept and stays in its other sections.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the item to remove.
    ///   - sectionIdentifier: The identifier of the section to remove it from.
    func removeItem(identifier: String, fromSectionWithIdentifier sectionIdentifier: String) async throws

    /// Updates an item everywhere it appears.
    ///
    /// - Parameter item: The item carrying the new name and weight.
    /// - Throws: ``EventListError/itemNotFound(identifier:)`` when the item does not exist.
    func updateItem(_ item: ListItem) async throws

    /// Deletes an item from every section. Runs keep their own copy, so past runs still show it.
    ///
    /// - Parameter identifier: The identifier of the item to delete. Does nothing if it does not exist.
    func deleteItem(identifier: String) async throws

    /// Moves an item to a new position within a section.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the item to move.
    ///   - sectionIdentifier: The identifier of the section containing the item.
    ///   - position: The new zero-based index, clamped to the section's bounds.
    /// - Throws: ``EventListError/sectionNotFound(identifier:)`` or
    ///   ``EventListError/itemNotFound(identifier:)`` when either does not exist.
    func moveItem(identifier: String, inSectionWithIdentifier sectionIdentifier: String, to position: Int) async throws

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

    /// Deletes an event. Its lists and its runs are kept.
    ///
    /// - Parameter identifier: The identifier of the event to delete. Does nothing if it does not exist.
    func deleteEvent(identifier: String) async throws

    /// Starts a new run of an event, snapshotting its lists, sections and items as they are now.
    ///
    /// - Parameter eventIdentifier: The identifier of the event to run.
    /// - Returns: The new run, with nothing completed.
    /// - Throws: ``EventListError/eventNotFound(identifier:)`` when the event does not exist.
    func startRun(ofEventWithIdentifier eventIdentifier: String) async throws -> EventRun

    /// Marks an item of one of a run's lists as completed or not completed.
    ///
    /// Each list has its own checkmark, so an item shared by two lists is completed separately in each.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the item in the run's snapshot.
    ///   - isCompleted: Whether the item is completed.
    ///   - listIdentifier: The identifier of the list in the run.
    ///   - runIdentifier: The identifier of the run.
    /// - Throws: ``EventListError/runNotFound(identifier:)``, ``EventListError/listNotFound(identifier:)``
    ///   when the list is not in the run, or ``EventListError/itemNotFound(identifier:)`` when the item is not in that list.
    func setItem(
        identifier: String,
        isCompleted: Bool,
        inListWithIdentifier listIdentifier: String,
        inRunWithIdentifier runIdentifier: String
    ) async throws

    /// Marks a run as completed, or reopens it.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the run.
    ///   - isComplete: Whether the run is completed. Completing records the completion date.
    /// - Throws: ``EventListError/runNotFound(identifier:)`` when the run does not exist.
    func setRun(identifier: String, isComplete: Bool) async throws

    /// Deletes a run and its completions. The event and its lists are kept.
    ///
    /// - Parameter identifier: The identifier of the run to delete. Does nothing if it does not exist.
    func deleteRun(identifier: String) async throws
}
