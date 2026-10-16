import Foundation
import Testing
@testable import AsyncNetworkSession

struct ListBuilderTests {
    @Test func decodeReturnsListsFromJSON() throws {
        let lists = try ListBuilder().decode(Data(#"[{"identifier":"a","title":"A","tasks":[]},{"identifier":"b","title":"B","tasks":[]}]"#.utf8))
        #expect(lists.count == 2)
        #expect(lists.first?.identifier == "a")
        #expect(lists.first?.title == "A")
    }

    @Test func decodeReturnsTasksInsideList() throws {
        let json = #"[{"identifier":"a","title":"A","tasks":[{"identifier":"1","title":"Buy milk","isComplete":true}]}]"#
        let lists = try ListBuilder().decode(Data(json.utf8))
        #expect(lists.first?.tasks.count == 1)
        #expect(lists.first?.tasks.first?.identifier == "1")
        #expect(lists.first?.tasks.first?.title == "Buy milk")
        #expect(lists.first?.tasks.first?.isComplete == true)
    }

    @Test func decodeThrowsOnInvalidData() {
        #expect(throws: (any Error).self) {
            try ListBuilder().decode(Data("not json".utf8))
        }
    }
}
