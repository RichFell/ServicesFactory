import Testing
@testable import AsyncNetworkSession

struct ListServiceImplementationTests {
    @Test func allListsReturnsNoListsByDefault() async throws {
        let service = ListServiceImplementation()
        let lists = try await service.allLists()
        #expect(lists.isEmpty)
    }
}
