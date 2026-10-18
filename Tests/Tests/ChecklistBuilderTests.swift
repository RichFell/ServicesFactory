//
//  ChecklistBuilderTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct ChecklistBuilderTests {
    private func decode(_ json: String) throws -> [Checklist] {
        try ChecklistBuilder().decode(Data(json.utf8))
    }

    @Test func decodeReturnsChecklistsFromJSON() throws {
        let checklists = try decode(#"[{"identifier":"a","title":"A","items":[]},{"identifier":"b","title":"B","items":[]}]"#)
        #expect(checklists.count == 2)
        #expect(checklists.first?.identifier == "a")
        #expect(checklists.first?.title == "A")
    }

    @Test func decodeWrapsFlatItemsInOneFlatChecklist() throws {
        let checklist = try #require(try decode(#"[{"identifier":"a","title":"A","items":[{"identifier":"1","title":"Milk"}]}]"#).first)

        #expect(checklist.isFlatList)
        #expect(checklist.type == .standard)
        #expect(checklist.components.count == 1)
        #expect(checklist.items.map(\.title) == ["Milk"])
        #expect(checklist.items.first?.weight == nil)
        #expect(!checklist.items[0].isCompleted)
    }

    @Test func decodeReturnsTypeWeightPriceAndImage() throws {
        let json = """
            [{"identifier":"a","title":"Pack","type":"weight","items":[
            {"identifier":"1","title":"Tent","weightInGrams":1500,"price":199.5,"imageData":"AQID","isCompleted":true}]}]
            """
        let checklist = try #require(try decode(json).first)
        let item = try #require(checklist.items.first)

        #expect(checklist.type == .weight)
        #expect(item.weight == Measurement(value: 1500, unit: .grams))
        #expect(item.price == Decimal(string: "199.5"))
        #expect(item.imageData == Data([1, 2, 3]))
        #expect(item.isCompleted)
    }

    @Test func decodeReturnsComponents() throws {
        let json = """
            [{"identifier":"a","title":"Shop","type":"price","components":[
            {"identifier":"c1","title":"Produce","items":[{"identifier":"1","title":"Apple"}]},
            {"identifier":"c2","items":[{"identifier":"2","title":"Bread"}]}]}]
            """
        let checklist = try #require(try decode(json).first)

        #expect(!checklist.isFlatList)
        #expect(checklist.components.map(\.identifier) == ["c1", "c2"])
        #expect(checklist.components.map(\.title) == ["Produce", ""])
        #expect(checklist.items.map(\.title) == ["Apple", "Bread"])
    }

    @Test func decodeFallsBackToStandardForUnknownType() throws {
        let checklist = try #require(try decode(#"[{"identifier":"a","title":"A","type":"color","items":[]}]"#).first)
        #expect(checklist.type == .standard)
    }

    @Test func decodeThrowsOnInvalidData() {
        #expect(throws: (any Error).self) {
            try ChecklistBuilder().decode(Data("not json".utf8))
        }
    }
}
