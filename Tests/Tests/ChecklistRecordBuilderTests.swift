//
//  ChecklistRecordBuilderTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct ChecklistRecordBuilderTests {
    private let builder = ChecklistRecordBuilder()

    private let tent = ChecklistItem(
        identifier: "tent",
        title: "Tent",
        weight: Measurement(value: 2, unit: .kilograms),
        price: Decimal(string: "9.5"),
        imageData: Data([1, 2, 3]),
        isCompleted: true
    )

    private var checklist: Checklist {
        Checklist(
            identifier: "pack",
            title: "Packing",
            type: .weight,
            isFlatList: false,
            components: [
                ChecklistComponent(identifier: "shelter", title: "Shelter", items: [tent]),
                ChecklistComponent(identifier: "kitchen", title: "Kitchen", items: [ChecklistItem(identifier: "stove", title: "Stove")])
            ]
        )
    }

    private func rebuild(_ records: ChecklistRecordBuilder.ChecklistRecords) -> [Checklist] {
        builder.checklists(from: [records.checklist], components: records.components, items: records.items)
    }

    @Test func recordsCarryTypeComponentsAndOrderedItems() {
        let records = builder.records(for: checklist)

        #expect(records.checklist.id == "pack")
        #expect(records.checklist.type == "weight")
        #expect(!records.checklist.isFlatList)
        #expect(records.components.map(\.id) == ["shelter", "kitchen"])
        #expect(records.components.map(\.position) == [0, 1])
        #expect(records.items.map(\.id) == ["tent", "stove"])
        #expect(records.items.map(\.componentID) == ["shelter", "kitchen"])
        #expect(records.items[0].weightInGrams == 2000)
    }

    @Test func checklistRoundTripsEveryItemProperty() throws {
        let rebuilt = try #require(rebuild(builder.records(for: checklist)).first)
        let item = try #require(rebuilt.items.first)

        #expect(rebuilt.type == .weight)
        #expect(!rebuilt.isFlatList)
        #expect(rebuilt.components.map(\.title) == ["Shelter", "Kitchen"])
        #expect(item.title == "Tent")
        #expect(item.weight == Measurement(value: 2000, unit: .grams))
        #expect(item.price == Decimal(string: "9.5"))
        #expect(item.imageData == Data([1, 2, 3]))
        #expect(item.isCompleted)
        #expect(rebuilt.items[1].weight == nil)
        #expect(!rebuilt.items[1].isCompleted)
    }

    @Test func flatChecklistIsOneUntitledComponentSharingTheChecklistIdentifier() throws {
        let flat = Checklist(identifier: "todo", items: [ChecklistItem(identifier: "x", title: "X")])

        let rebuilt = try #require(rebuild(builder.records(for: flat)).first)

        #expect(rebuilt.isFlatList)
        #expect(rebuilt.components.map(\.identifier) == ["todo"])
        #expect(rebuilt.components.map(\.title) == [""])
    }

    @Test func componentsAndItemsAreOrderedByPosition() throws {
        let records = builder.records(for: checklist)

        let rebuilt = try #require(
            builder.checklists(
                from: [records.checklist],
                components: records.components.reversed(),
                items: records.items.reversed()
            ).first
        )

        #expect(rebuilt.components.map(\.identifier) == ["shelter", "kitchen"])
    }

    @Test func itemsAreMatchedToTheirOwnComponentOnly() throws {
        let other = builder.records(for: Checklist(identifier: "other", items: [ChecklistItem(identifier: "x", title: "X")]))
        let records = builder.records(for: checklist)

        let rebuilt = builder.checklists(
            from: [records.checklist, other.checklist],
            components: records.components + other.components,
            items: records.items + other.items
        )

        #expect(rebuilt.map { $0.items.map(\.identifier) } == [["tent", "stove"], ["x"]])
    }

    @Test func unknownStoredTypeFallsBackToStandard() {
        var record = builder.records(for: checklist).checklist
        record.type = "color"

        #expect(record.makeChecklist(components: []).type == .standard)
    }

    @Test func copyHasNewIdentifiersAndNothingCompleted() {
        var count = 0
        let copy = builder.copy(of: checklist, title: "Copy") {
            count += 1
            return "id\(count)"
        }

        #expect(copy.identifier == "id1")
        #expect(copy.title == "Copy")
        #expect(copy.type == .weight)
        #expect(!copy.isFlatList)
        #expect(copy.components.map(\.identifier) == ["id2", "id4"])
        #expect(copy.items.map(\.identifier) == ["id3", "id5"])
        #expect(copy.items.map(\.title) == ["Tent", "Stove"])
        #expect(copy.items[0].weight == Measurement(value: 2, unit: .kilograms))
        #expect(copy.items[0].imageData == Data([1, 2, 3]))
        #expect(copy.items.allSatisfy { !$0.isCompleted })
    }
}
