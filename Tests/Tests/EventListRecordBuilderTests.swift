//
//  EventListRecordBuilderTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct EventListRecordBuilderTests {
    private let builder = EventListRecordBuilder()

    private let list = List(
        identifier: "pack",
        title: "Packing",
        fields: [.weight],
        items: [
            ListItem(identifier: "a", name: "A", weight: Measurement(value: 2, unit: .kilograms)),
            ListItem(identifier: "b", name: "B")
        ]
    )

    @Test func recordsCarryListFieldsAndOrderedItems() {
        let records = builder.records(for: list)

        #expect(records.list.id == "pack")
        #expect(records.fields.map(\.field) == ["weight"])
        #expect(records.items.map(\.id) == ["a", "b"])
        #expect(records.links.map(\.itemID) == ["a", "b"])
        #expect(records.links.map(\.position) == [0, 1])
        #expect(records.items[0].weightInGrams == 2000)
        #expect(records.items[1].weightInGrams == nil)
    }

    @Test func listsShareAnItemThroughItsLinks() {
        let shared = ListItem(identifier: "a", name: "A")
        let first = builder.records(for: List(identifier: "one", items: [shared]))
        let second = builder.records(for: List(identifier: "two", items: [shared]))

        let lists = builder.lists(
            from: [first.list, second.list],
            fields: [],
            items: first.items,
            links: first.links + second.links
        )

        #expect(lists.map { $0.items.map(\.identifier) } == [["a"], ["a"]])
    }

    @Test func listsSkipLinksForMissingItems() {
        let records = builder.records(for: list)

        let lists = builder.lists(
            from: [records.list],
            fields: records.fields,
            items: [records.items[1]],
            links: records.links
        )

        #expect(lists[0].items.map(\.identifier) == ["b"])
    }

    @Test func listsRebuildFromRecordsMatchingByListID() {
        let records = builder.records(for: list)
        let otherRecords = builder.records(for: List(identifier: "other", title: "Other"))

        let lists = builder.lists(
            from: [records.list, otherRecords.list],
            fields: records.fields + otherRecords.fields,
            items: records.items + otherRecords.items,
            links: records.links.reversed() + otherRecords.links
        )

        #expect(lists.map(\.identifier) == ["pack", "other"])
        #expect(lists[0].fields == [.weight])
        #expect(lists[0].items.map(\.identifier) == ["a", "b"])
        #expect(lists[1].items.isEmpty)
    }

    @Test func eventsResolveOrderedListsAndCompletedItems() {
        let other = List(identifier: "other", title: "Other")
        let event = Event(
            identifier: "trip",
            title: "Trip",
            lists: [other, list],
            completedItemIdentifiers: ["a"],
            isComplete: true
        )

        let events = builder.events(
            from: [EventRecord(event)],
            lists: [list, other],
            eventLists: EventListRecord.records(for: event).reversed(),
            completedItems: EventCompletedItemRecord.records(for: event)
        )

        #expect(events.count == 1)
        #expect(events[0].identifier == "trip")
        #expect(events[0].lists.map(\.identifier) == ["other", "pack"])
        #expect(events[0].completedItemIdentifiers == ["a"])
        #expect(events[0].isComplete)
    }

    @Test func eventsSkipJoinRowsForMissingLists() {
        let event = Event(identifier: "trip", title: "Trip", lists: [list])

        let events = builder.events(
            from: [EventRecord(event)],
            lists: [],
            eventLists: EventListRecord.records(for: event),
            completedItems: []
        )

        #expect(events[0].lists.isEmpty)
    }
}
