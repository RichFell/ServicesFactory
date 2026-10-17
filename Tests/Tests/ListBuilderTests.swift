import Foundation
import Testing
@testable import ServicesFactory

struct ListBuilderTests {
    @Test func decodeReturnsListsFromJSON() throws {
        let lists = try ListBuilder().decode(Data(#"[{"identifier":"a","title":"A","items":[]},{"identifier":"b","title":"B","items":[]}]"#.utf8))
        #expect(lists.count == 2)
        #expect(lists.first?.identifier == "a")
        #expect(lists.first?.title == "A")
    }

    @Test func decodeReturnsItemsInsideList() throws {
        let json = #"[{"identifier":"a","title":"A","items":[{"identifier":"1","name":"Buy milk"}]}]"#
        let lists = try ListBuilder().decode(Data(json.utf8))
        #expect(lists.first?.items.count == 1)
        #expect(lists.first?.items.first?.identifier == "1")
        #expect(lists.first?.items.first?.name == "Buy milk")
        #expect(lists.first?.items.first?.weight == nil)
        #expect(lists.first?.fields.isEmpty == true)
    }

    @Test func decodeReturnsWeightsAndFieldsForPackingList() throws {
        let json = #"[{"identifier":"a","title":"Pack","fields":["weight"],"items":[{"identifier":"1","name":"Tent","weightInGrams":1500}]}]"#
        let lists = try ListBuilder().decode(Data(json.utf8))
        #expect(lists.first?.fields == [.weight])
        #expect(lists.first?.items.first?.weight == Measurement(value: 1500, unit: .grams))
    }

    @Test func decodeIgnoresUnknownFields() throws {
        let json = #"[{"identifier":"a","title":"A","fields":["weight","color"],"items":[]}]"#
        let lists = try ListBuilder().decode(Data(json.utf8))
        #expect(lists.first?.fields == [.weight])
    }

    @Test func decodeThrowsOnInvalidData() {
        #expect(throws: (any Error).self) {
            try ListBuilder().decode(Data("not json".utf8))
        }
    }
}
