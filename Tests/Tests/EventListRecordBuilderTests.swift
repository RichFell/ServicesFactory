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
        fields: [.weight, .price],
        sections: [
            ListSection(
                identifier: "shelter",
                title: "Shelter",
                items: [
                    ListItem(
                        identifier: "a",
                        name: "A",
                        values: [.weight: .weight(Measurement(value: 2, unit: .kilograms)), .price: .price(Decimal(string: "9.5")!)]
                    )
                ]
            ),
            ListSection(identifier: "kitchen", title: "Kitchen", items: [ListItem(identifier: "b", name: "B")])
        ]
    )

    /// Rebuilds lists from the rows persisting `records`.
    private func rebuild(_ records: [EventListRecordBuilder.ListRecords]) -> [List] {
        builder.lists(
            from: records.map(\.list),
            fields: records.flatMap(\.fields),
            sections: records.flatMap(\.sections),
            items: records.flatMap(\.items).map(\.item),
            values: records.flatMap(\.items).flatMap(\.values),
            links: records.flatMap(\.links)
        )
    }

    @Test func recordsCarryFieldsSectionsItemsAndValues() {
        let records = builder.records(for: list)

        #expect(records.list.id == "pack")
        #expect(Set(records.fields.map(\.field)) == ["weight", "price"])
        #expect(records.sections.map(\.id) == ["shelter", "kitchen"])
        #expect(records.sections.map(\.position) == [0, 1])
        #expect(records.items.map(\.item.id) == ["a", "b"])
        #expect(records.links.map(\.sectionID) == ["shelter", "kitchen"])
        #expect(records.items[0].values.count == 2)
        #expect(records.items[1].values.isEmpty)
    }

    @Test func listRoundTripsSectionsAndValues() {
        let lists = rebuild([builder.records(for: list)])

        #expect(lists.count == 1)
        #expect(lists[0].fields == [.weight, .price])
        #expect(lists[0].sections.map(\.title) == ["Shelter", "Kitchen"])
        #expect(lists[0].items.map(\.identifier) == ["a", "b"])
        #expect(lists[0].items[0].weight == Measurement(value: 2000, unit: .grams))
        #expect(lists[0].items[0].price == Decimal(string: "9.5"))
        #expect(lists[0].items[1].values.isEmpty)
    }

    @Test func plainListIsOneUntitledSectionWithTheListIdentifier() {
        let plain = List(identifier: "todo", items: [ListItem(identifier: "x", name: "X")])

        let rebuilt = rebuild([builder.records(for: plain)])

        #expect(rebuilt[0].sections.map(\.identifier) == ["todo"])
        #expect(rebuilt[0].sections.map(\.title) == [""])
    }

    @Test func itemAppearingInTwoSectionsIsStoredOnce() {
        let shared = ListItem(identifier: "a", name: "A")
        let twice = List(
            identifier: "l",
            sections: [
                ListSection(identifier: "s1", items: [shared]),
                ListSection(identifier: "s2", items: [shared])
            ]
        )

        let records = builder.records(for: twice)

        #expect(records.items.count == 1)
        #expect(records.links.count == 2)
    }

    @Test func listsShareAnItemThroughItsLinks() {
        let shared = ListItem(identifier: "a", name: "A")
        let first = builder.records(for: List(identifier: "one", items: [shared]))
        let second = builder.records(for: List(identifier: "two", items: [shared]))

        let lists = builder.lists(
            from: [first.list, second.list],
            fields: [],
            sections: first.sections + second.sections,
            items: first.items.map(\.item),
            values: [],
            links: first.links + second.links
        )

        #expect(lists.map { $0.items.map(\.identifier) } == [["a"], ["a"]])
    }

    @Test func listsSkipLinksForMissingItems() {
        let records = builder.records(for: list)

        let lists = builder.lists(
            from: [records.list],
            fields: records.fields,
            sections: records.sections,
            items: [records.items[1].item],
            values: [],
            links: records.links
        )

        #expect(lists[0].items.map(\.identifier) == ["b"])
    }

    @Test func listsOrderSectionsAndItemsByPosition() {
        let records = builder.records(for: list)

        let lists = builder.lists(
            from: [records.list],
            fields: records.fields,
            sections: records.sections.reversed(),
            items: records.items.map(\.item).reversed(),
            values: records.items.flatMap(\.values),
            links: records.links.reversed()
        )

        #expect(lists[0].sections.map(\.identifier) == ["shelter", "kitchen"])
        #expect(lists[0].items.map(\.identifier) == ["a", "b"])
    }

    @Test func valuesWithUnknownFieldOrUnreadableDataAreSkipped() {
        let item = ListItemRecord(ListItem(identifier: "a", name: "A"))
        let values = [
            ListItemValueRecord(itemID: "a", field: "color", value: "red"),
            ListItemValueRecord(itemID: "a", field: "weight", value: "heavy"),
            ListItemValueRecord(itemID: "a", field: "price", value: "3")
        ]

        let rebuilt = item.makeListItem(values: values)

        #expect(rebuilt.values == [.price: .price(3)])
    }

    @Test func eventsResolveOrderedLists() {
        let other = List(identifier: "other", title: "Other")
        let event = Event(identifier: "trip", title: "Trip", lists: [other, list])

        let events = builder.events(
            from: [EventRecord(event)],
            lists: [list, other],
            eventLists: EventListRecord.records(for: event).reversed()
        )

        #expect(events.count == 1)
        #expect(events[0].identifier == "trip")
        #expect(events[0].lists.map(\.identifier) == ["other", "pack"])
    }

    @Test func eventsSkipJoinRowsForMissingLists() {
        let event = Event(identifier: "trip", title: "Trip", lists: [list])

        let events = builder.events(
            from: [EventRecord(event)],
            lists: [],
            eventLists: EventListRecord.records(for: event)
        )

        #expect(events[0].lists.isEmpty)
    }

    @Test func runRoundTripsThroughItsSnapshotAndCompletions() throws {
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let run = EventRun(
            identifier: "run",
            eventIdentifier: "trip",
            title: "Trip",
            lists: [list],
            completedItemIdentifiers: ["pack": ["a"]],
            isComplete: true,
            startedAt: startedAt,
            completedAt: startedAt.addingTimeInterval(60)
        )
        let records = try builder.records(for: run)

        let runs = try builder.runs(from: [records.run], completedItems: records.completedItems)

        #expect(runs.count == 1)
        #expect(runs[0].lists.map(\.identifier) == ["pack"])
        #expect(runs[0].lists[0].fields == [.weight, .price])
        #expect(runs[0].lists[0].sections.map(\.title) == ["Shelter", "Kitchen"])
        #expect(runs[0].lists[0].items.map(\.identifier) == ["a", "b"])
        #expect(runs[0].lists[0].items[0].weight == Measurement(value: 2000, unit: .grams))
        #expect(runs[0].lists[0].items[0].price == Decimal(string: "9.5"))
        #expect(runs[0].completedItemIdentifiers == ["pack": ["a"]])
        #expect(runs[0].isComplete)
        #expect(runs[0].startedAt == startedAt)
        #expect(runs[0].completedAt == startedAt.addingTimeInterval(60))
    }

    @Test func runSnapshotSkipsUnknownFieldsAndValuesFromNewerVersions() throws {
        let json = """
            {"lists":[{"identifier":"l","title":"L","fields":["weight","color"],"sections":[
            {"identifier":"s","title":"","items":[{"identifier":"a","name":"A","values":{"color":"red","price":"2"}}]}]}]}
            """

        let lists = try EventRunSnapshot.decode(json: json).makeLists()

        #expect(lists[0].fields == [.weight])
        #expect(lists[0].items[0].values == [.price: .price(2)])
    }

    @Test func corruptSnapshotThrows() throws {
        let run = EventRun(identifier: "run", eventIdentifier: "trip", title: "Trip")
        var record = try builder.records(for: run).run
        record.snapshot = "not json"

        #expect(throws: (any Error).self) {
            try builder.runs(from: [record], completedItems: [])
        }
    }
}
