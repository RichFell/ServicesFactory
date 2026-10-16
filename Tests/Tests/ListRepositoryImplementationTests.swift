import Foundation
import Testing
@testable import AsyncNetworkSession

struct ListRepositoryImplementationTests {
    @Test func allListsDecodesFetchedData() async throws {
        let repository = ListRepositoryImplementation { Data(#"[{"tasks":[]}]"#.utf8) }
        let lists = try await repository.allLists()
        #expect(lists.count == 1)
    }

    @Test func allListsPropagatesFetchErrors() async {
        struct FetchError: Error {}
        let repository = ListRepositoryImplementation { throw FetchError() }
        await #expect(throws: FetchError.self) {
            try await repository.allLists()
        }
    }
}
