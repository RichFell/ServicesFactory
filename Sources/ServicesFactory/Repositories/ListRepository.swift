/// A repository that retrieves list models from a data source.
protocol ListRepository: Sendable {
    /// Retrieves all available lists.
    func allLists() async throws -> [List]
}
