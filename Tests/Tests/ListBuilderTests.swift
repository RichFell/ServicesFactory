import Foundation
import Testing
@testable import AsyncNetworkSession

struct ListBuilderTests {
    @Test func decodeReturnsListsFromJSON() throws {
        let lists = try ListBuilder().decode(Data(#"[{"tasks":[]},{"tasks":[]}]"#.utf8))
        #expect(lists.count == 2)
    }

    @Test func decodeReturnsTasksInsideList() throws {
        let json = #"[{"tasks":[{"identifier":"1","title":"Buy milk"}]}]"#
        let lists = try ListBuilder().decode(Data(json.utf8))
        #expect(lists.first?.tasks.count == 1)
        #expect(lists.first?.tasks.first?.identifier == "1")
        #expect(lists.first?.tasks.first?.title == "Buy milk")
    }

    @Test func decodeThrowsOnInvalidData() {
        #expect(throws: (any Error).self) {
            try ListBuilder().decode(Data("not json".utf8))
        }
    }
}
