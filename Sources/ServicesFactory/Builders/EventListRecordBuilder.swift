//
//  EventListRecordBuilder.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

/// Maps between public ``List`` models and their stored database records.
struct EventListRecordBuilder: Sendable {

    init() {}

    /// Splits `list` into the rows that persist it.
    ///
    /// An item that appears more than once in the list is stored once.
    func records(for list: List) -> ListRecords {
        var seen = Set<String>()
        let items = list.items.filter { seen.insert($0.identifier).inserted }
        return ListRecords(
            list: ListRecord(list),
            fields: ListFieldRecord.records(for: list),
            sections: ListSectionRecord.records(for: list),
            items: items.map(records(for:)),
            links: ListItemLinkRecord.records(for: list)
        )
    }

    /// Splits `item` into the rows that persist it.
    func records(for item: ListItem) -> ItemRecords {
        ItemRecords(item: ListItemRecord(item), values: ListItemValueRecord.records(for: item))
    }

    /// Rebuilds public lists from stored rows, in the order of `lists`.
    ///
    /// Fields and sections are matched to their list by `listID`, and sections ordered by `position`.
    /// Items are resolved from `items` through each section's `links`, ordered by `position`, with
    /// their `values` attached. Links pointing at a missing item are skipped.
    func lists(
        from lists: [ListRecord],
        fields: [ListFieldRecord],
        sections: [ListSectionRecord],
        items: [ListItemRecord],
        values: [ListItemValueRecord],
        links: [ListItemLinkRecord]
    ) -> [List] {
        let fieldsByList = Dictionary(grouping: fields, by: \.listID)
        let sectionsByList = Dictionary(grouping: sections, by: \.listID)
        let linksBySection = Dictionary(grouping: links, by: \.sectionID)
        let valuesByItem = Dictionary(grouping: values, by: \.itemID)
        let itemsByID = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return lists.map { record in
            let listSections = (sectionsByList[record.id] ?? [])
                .sorted { $0.position < $1.position }
                .map { section in
                    let sectionItems = (linksBySection[section.id] ?? [])
                        .sorted { $0.position < $1.position }
                        .compactMap { itemsByID[$0.itemID]?.makeListItem(values: valuesByItem[$0.itemID] ?? []) }
                    return ListSection(identifier: section.id, title: section.title, items: sectionItems)
                }
            return record.makeList(fields: fieldsByList[record.id] ?? [], sections: listSections)
        }
    }

    /// Rebuilds public events from stored rows, in the order of `events`.
    ///
    /// Each event's lists are resolved from `lists` through its `eventLists` join rows, ordered by
    /// `position`. Join rows pointing at a missing list are skipped.
    func events(
        from events: [EventRecord],
        lists: [List],
        eventLists: [EventListRecord]
    ) -> [Event] {
        let listsByID = Dictionary(lists.map { ($0.identifier, $0) }, uniquingKeysWith: { first, _ in first })
        let joinsByEvent = Dictionary(grouping: eventLists, by: \.eventID)
        return events.map { record in
            let eventLists = (joinsByEvent[record.id] ?? [])
                .sorted { $0.position < $1.position }
                .compactMap { listsByID[$0.listID] }
            return record.makeEvent(lists: eventLists)
        }
    }

    /// Splits `run` into the rows that persist it: the run with its encoded list snapshot, and its completions.
    func records(for run: EventRun) throws -> RunRecords {
        RunRecords(
            run: try EventRunRecord(run),
            completedItems: EventRunCompletedItemRecord.records(for: run)
        )
    }

    /// Rebuilds public runs from stored rows, in the order of `runs`.
    ///
    /// Each run's lists are decoded from its own snapshot, never from the live lists.
    ///
    /// - Throws: A decoding error when a run's snapshot is corrupt.
    func runs(
        from runs: [EventRunRecord],
        completedItems: [EventRunCompletedItemRecord]
    ) throws -> [EventRun] {
        let completedByRun = Dictionary(grouping: completedItems, by: \.runID)
        return try runs.map { try $0.makeRun(completedItems: completedByRun[$0.id] ?? []) }
    }
}

// MARK: - Nested Types

extension EventListRecordBuilder {
    /// The rows that together persist a single ``List``.
    struct ListRecords: Equatable, Sendable {
        let list: ListRecord
        let fields: [ListFieldRecord]
        let sections: [ListSectionRecord]
        let items: [ItemRecords]
        let links: [ListItemLinkRecord]
    }

    /// The rows that together persist a single ``ListItem``.
    struct ItemRecords: Equatable, Sendable {
        let item: ListItemRecord
        let values: [ListItemValueRecord]
    }

    /// The rows that together persist a single ``EventRun``.
    struct RunRecords: Equatable, Sendable {
        let run: EventRunRecord
        let completedItems: [EventRunCompletedItemRecord]
    }
}
