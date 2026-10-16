import Foundation
import Testing
@testable import AsyncNetworkSession

struct ListBuilderTests {
    @Test func decodeReturnsListsFromJSON() throws {
        let lists = try ListBuilder().decode(Data("[{},{}]".utf8))
        #expect(lists.count == 2)
    }

    @Test func decodeThrowsOnInvalidData() {
        #expect(throws: (any Error).self) {
            try ListBuilder().decode(Data("not json".utf8))
        }
    }
}
