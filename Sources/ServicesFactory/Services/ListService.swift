/// A service that retrieves list models.
public protocol ListService: Service {
    /// Retrieves all available lists.
    func allLists() async throws -> [List]
}


