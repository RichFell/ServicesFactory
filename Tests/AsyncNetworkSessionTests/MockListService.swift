@testable import AsyncNetworkSession

/// A ``ListService`` stand-in used to register custom services with a factory.
final class MockListService: ListService {
    func allLists() async throws -> [List] {
        []
    }
}
