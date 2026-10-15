import Testing
@testable import AsyncNetworkSession

struct ListServiceImplementationTests {
    @Test func allListsReturnsNoListsByDefault() async throws {
        let service = ListServiceImplementation()
        let lists = try await service.allLists()
        #expect(lists.isEmpty)
    }

    @Test func servicesReturnsListServiceImplementationAndReusesIt() async throws {
        let services = Services()
        let first: ListServiceImplementation = await services.service(for: .list)
        let second: ListServiceImplementation = await services.service(for: .list)
        #expect(first === second)
    }
}
