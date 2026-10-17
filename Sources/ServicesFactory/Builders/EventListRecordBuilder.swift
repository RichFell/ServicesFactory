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
    func records(for list: List) -> ListRecords {
        ListRecords(
            list: ListRecord(list),
            fields: ListFieldRecord.records(for: list),
            items: ListItemRecord.records(for: list)
        )
    }

    /// Rebuilds public lists from stored rows, in the order of `lists`.
    ///
    /// Fields and items are matched to their list by `listID`.
    func lists(
        from lists: [ListRecord],
        fields: [ListFieldRecord],
        items: [ListItemRecord]
    ) -> [List] {
        let fieldsByList = Dictionary(grouping: fields, by: \.listID)
        let itemsByList = Dictionary(grouping: items, by: \.listID)
        return lists.map { record in
            record.makeList(
                fields: fieldsByList[record.id] ?? [],
                items: itemsByList[record.id] ?? []
            )
        }
    }

    /// Rebuilds public events from stored rows, in the order of `events`.
    ///
    /// Each event's lists are resolved from `lists` through its `eventLists` join rows, ordered by
    /// `position`. Join rows pointing at a missing list are skipped.
    func events(
        from events: [EventRecord],
        lists: [List],
        eventLists: [EventListRecord],
        completedItems: [EventCompletedItemRecord]
    ) -> [Event] {
        let listsByID = Dictionary(lists.map { ($0.identifier, $0) }, uniquingKeysWith: { first, _ in first })
        let joinsByEvent = Dictionary(grouping: eventLists, by: \.eventID)
        let completedByEvent = Dictionary(grouping: completedItems, by: \.eventID)
        return events.map { record in
            let eventLists = (joinsByEvent[record.id] ?? [])
                .sorted { $0.position < $1.position }
                .compactMap { listsByID[$0.listID] }
            return record.makeEvent(lists: eventLists, completedItems: completedByEvent[record.id] ?? [])
        }
    }
}

// MARK: - Nested Types

extension EventListRecordBuilder {
    /// The rows that together persist a single ``List``.
    struct ListRecords: Equatable, Sendable {
        let list: ListRecord
        let fields: [ListFieldRecord]
        let items: [ListItemRecord]
    }
}
