//
//  EventListWritableRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation

/// An ``EventListRepository`` that can also create, edit and delete lists, sections, items, events and runs.
///
/// Items are standalone and can belong to several sections. Removing a list or section or unlinking
/// an item never deletes the other side; only ``deleteItem(identifier:)`` removes an item.
protocol EventListWritableRepository: EventListRepository {
    /// Stores a new list with its fields, sections and items. Items that already exist are linked, not duplicated.
    func createList(_ list: List) async throws

    /// Updates the title and fields of the list with the same identifier. Sections and items are left unchanged.
    ///
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when the list does not exist.
    func updateList(_ list: List) async throws

    /// Deletes the list, its sections and their links to items. The items themselves are kept. Does nothing if the list is missing.
    func deleteList(identifier: String) async throws

    /// Adds `section`, with its items, to the end of a list. Items that already exist are linked, not duplicated.
    ///
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when the list does not exist.
    func addSection(_ section: ListSection, toListWithIdentifier listIdentifier: String) async throws

    /// Updates the title of the section with the same identifier. Its items are left unchanged.
    ///
    /// - Throws: ``EventListError/sectionNotFound(identifier:)`` when the section does not exist.
    func updateSection(_ section: ListSection) async throws

    /// Deletes the section and its links to items. The items themselves are kept. Does nothing if the section is missing.
    func deleteSection(identifier: String) async throws

    /// Adds `item` to the end of a section, creating the item if it is new or updating it if it exists.
    ///
    /// - Throws: ``EventListError/sectionNotFound(identifier:)`` when the section does not exist.
    func addItem(_ item: ListItem, toSectionWithIdentifier sectionIdentifier: String) async throws

    /// Unlinks an item from a section. The item is kept and stays in its other sections.
    func removeItem(identifier: String, fromSectionWithIdentifier sectionIdentifier: String) async throws

    /// Updates the item with the same identifier in every section that contains it.
    ///
    /// - Throws: ``EventListError/itemNotFound(identifier:)`` when the item does not exist.
    func updateItem(_ item: ListItem) async throws

    /// Deletes the item and its links to every section. Runs keep their own copy of the item.
    func deleteItem(identifier: String) async throws

    /// Moves an item to `position` within a section. The position is clamped to the section's bounds.
    ///
    /// - Throws: ``EventListError/sectionNotFound(identifier:)`` or ``EventListError/itemNotFound(identifier:)``.
    func moveItem(identifier: String, inSectionWithIdentifier sectionIdentifier: String, to position: Int) async throws

    /// Stores a new event that uses the already stored lists named by `event.lists`, in order.
    ///
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when a list does not exist.
    func createEvent(_ event: Event) async throws

    /// Updates the title and lists of the event with the same identifier. Existing runs are unchanged.
    ///
    /// - Throws: ``EventListError/eventNotFound(identifier:)`` or ``EventListError/listNotFound(identifier:)``.
    func updateEvent(_ event: Event) async throws

    /// Deletes the event. Its runs are kept. Does nothing if the event is missing.
    func deleteEvent(identifier: String) async throws

    /// Starts a run of an event, snapshotting the event's lists, sections and items as they are now.
    ///
    /// - Throws: ``EventListError/eventNotFound(identifier:)`` when the event does not exist.
    /// - Returns: The new run.
    func startRun(
        ofEventWithIdentifier eventIdentifier: String,
        identifier: String,
        startedAt: Date
    ) async throws -> EventRun

    /// Marks an item of one of a run's lists as completed or not completed.
    ///
    /// - Throws: ``EventListError/runNotFound(identifier:)``, ``EventListError/listNotFound(identifier:)``
    ///   when the list is not in the run, or ``EventListError/itemNotFound(identifier:)`` when the item is not in that list.
    func setItem(
        identifier: String,
        isCompleted: Bool,
        inListWithIdentifier listIdentifier: String,
        inRunWithIdentifier runIdentifier: String
    ) async throws

    /// Marks a run as completed (recording `date`) or reopens it.
    ///
    /// - Throws: ``EventListError/runNotFound(identifier:)`` when the run does not exist.
    func setRun(
        identifier: String,
        isComplete: Bool,
        at date: Date
    ) async throws

    /// Deletes a run and its completions. Does nothing if the run is missing.
    func deleteRun(identifier: String) async throws
}
