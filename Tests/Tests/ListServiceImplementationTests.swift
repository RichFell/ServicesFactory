import Testing
@testable import ServicesFactory

struct ListServiceImplementationTests {
    @Test func allListsReturnsNoListsByDefault() async throws {
        let service = ListServiceImplementation()
        let lists = try await service.allLists()
        #expect(lists.isEmpty)
    }
}
