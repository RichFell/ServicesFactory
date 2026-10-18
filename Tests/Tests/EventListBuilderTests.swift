//
//  EventListBuilderTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct EventListBuilderTests {
    @Test func decodeReturnsListsFromJSON() throws {
        let lists = try EventListBuilder().decode(Data(#"[{"identifier":"a","title":"A","items":[]},{"identifier":"b","title":"B","items":[]}]"#.utf8))
        #expect(lists.count == 2)
        #expect(lists.first?.identifier == "a")
        #expect(lists.first?.title == "A")
    }

    @Test func decodeReturnsItemsInsideList() throws {
        let json = #"[{"identifier":"a","title":"A","items":[{"identifier":"1","name":"Buy milk"}]}]"#
        let lists = try EventListBuilder().decode(Data(json.utf8))
        #expect(lists.first?.items.count == 1)
        #expect(lists.first?.items.first?.identifier == "1")
        #expect(lists.first?.items.first?.name == "Buy milk")
        #expect(lists.first?.items.first?.weight == nil)
        #expect(lists.first?.fields.isEmpty == true)
    }

    @Test func decodeReturnsWeightsAndFieldsForPackingList() throws {
        let json = #"[{"identifier":"a","title":"Pack","fields":["weight"],"items":[{"identifier":"1","name":"Tent","weightInGrams":1500}]}]"#
        let lists = try EventListBuilder().decode(Data(json.utf8))
        #expect(lists.first?.fields == [.weight])
        #expect(lists.first?.items.first?.weight == Measurement(value: 1500, unit: .grams))
    }

    @Test func decodeReturnsSectionsAndPrices() throws {
        let json = #"""
            [{"identifier":"a","title":"Shop","fields":["price"],"sections":[
            {"identifier":"s1","title":"Produce","items":[{"identifier":"1","name":"Apple","price":0.5}]},
            {"identifier":"s2","items":[{"identifier":"2","name":"Bread"}]}]}]
            """#
        let list = try #require(try EventListBuilder().decode(Data(json.utf8)).first)
        #expect(list.fields == [.price])
        #expect(list.sections.map(\.identifier) == ["s1", "s2"])
        #expect(list.sections.map(\.title) == ["Produce", ""])
        #expect(list.items.map(\.name) == ["Apple", "Bread"])
        #expect(list.items.first?.price == Decimal(string: "0.5"))
    }

    @Test func decodeWrapsFlatItemsInOneSectionWithTheListIdentifier() throws {
        let json = #"[{"identifier":"a","title":"A","items":[{"identifier":"1","name":"Milk"}]}]"#
        let list = try #require(try EventListBuilder().decode(Data(json.utf8)).first)
        #expect(list.sections.map(\.identifier) == ["a"])
    }

    @Test func decodeIgnoresUnknownFields() throws {
        let json = #"[{"identifier":"a","title":"A","fields":["weight","color"],"items":[]}]"#
        let lists = try EventListBuilder().decode(Data(json.utf8))
        #expect(lists.first?.fields == [.weight])
    }

    @Test func decodeThrowsOnInvalidData() {
        #expect(throws: (any Error).self) {
            try EventListBuilder().decode(Data("not json".utf8))
        }
    }
}
