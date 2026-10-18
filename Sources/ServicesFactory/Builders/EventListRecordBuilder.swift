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
            items: list.items.map(ListItemRecord.init),
            links: ListItemLinkRecord.records(for: list)
        )
    }

    /// Rebuilds public lists from stored rows, in the order of `lists`.
    ///
    /// Fields are matched to their list by `listID`. Items are resolved from `items` through the
    /// list's `links`, ordered by `position`. Links pointing at a missing item are skipped.
    func lists(
        from lists: [ListRecord],
        fields: [ListFieldRecord],
        items: [ListItemRecord],
        links: [ListItemLinkRecord]
    ) -> [List] {
        let fieldsByList = Dictionary(grouping: fields, by: \.listID)
        let linksByList = Dictionary(grouping: links, by: \.listID)
        let itemsByID = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return lists.map { record in
            let listItems = (linksByList[record.id] ?? [])
                .sorted { $0.position < $1.position }
                .compactMap { itemsByID[$0.itemID]?.makeListItem() }
            return record.makeList(fields: fieldsByList[record.id] ?? [], items: listItems)
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

    /// Splits `run` into the rows that persist it, including its list snapshot.
    func records(for run: EventRun) -> RunRecords {
        RunRecords(
            run: EventRunRecord(run),
            lists: EventRunListRecord.records(for: run),
            fields: EventRunListFieldRecord.records(for: run),
            items: EventRunItemRecord.records(for: run),
            completedItems: EventRunCompletedItemRecord.records(for: run)
        )
    }

    /// Rebuilds public runs from stored rows, in the order of `runs`.
    ///
    /// Each run's lists are rebuilt from its own snapshot rows, ordered by `position`, never from
    /// the live lists.
    func runs(
        from runs: [EventRunRecord],
        lists: [EventRunListRecord],
        fields: [EventRunListFieldRecord],
        items: [EventRunItemRecord],
        completedItems: [EventRunCompletedItemRecord]
    ) -> [EventRun] {
        let listsByRun = Dictionary(grouping: lists, by: \.runID)
        let fieldsByRun = Dictionary(grouping: fields, by: \.runID)
        let itemsByRun = Dictionary(grouping: items, by: \.runID)
        let completedByRun = Dictionary(grouping: completedItems, by: \.runID)
        return runs.map { record in
            let snapshotLists = snapshotLists(
                from: listsByRun[record.id] ?? [],
                fields: fieldsByRun[record.id] ?? [],
                items: itemsByRun[record.id] ?? []
            )
            return record.makeRun(lists: snapshotLists, completedItems: completedByRun[record.id] ?? [])
        }
    }

    /// Rebuilds one run's lists from its snapshot rows, ordered by `position`.
    private func snapshotLists(
        from lists: [EventRunListRecord],
        fields: [EventRunListFieldRecord],
        items: [EventRunItemRecord]
    ) -> [List] {
        let fieldsByList = Dictionary(grouping: fields, by: \.listID)
        let itemsByList = Dictionary(grouping: items, by: \.listID)
        return lists.sorted { $0.position < $1.position }.map { record in
            List(
                identifier: record.listID,
                title: record.title,
                fields: Set((fieldsByList[record.listID] ?? []).compactMap { ListField(rawValue: $0.field) }),
                items: (itemsByList[record.listID] ?? [])
                    .sorted { $0.position < $1.position }
                    .map { $0.makeListItem() }
            )
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
        let links: [ListItemLinkRecord]
    }

    /// The rows that together persist a single ``EventRun`` and its list snapshot.
    struct RunRecords: Equatable, Sendable {
        let run: EventRunRecord
        let lists: [EventRunListRecord]
        let fields: [EventRunListFieldRecord]
        let items: [EventRunItemRecord]
        let completedItems: [EventRunCompletedItemRecord]
    }
}
