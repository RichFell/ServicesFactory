import Foundation

/// Decodes raw list data into ``List`` models.
struct ListBuilder: Sendable {

    init() {}

    /// Decodes `data` into an array of lists.
    func decode(_ data: Data) throws -> [List] {
        try JSONDecoder().decode([RawList].self, from: data).map(\.model)
    }
    
    /// Raw representation of a ``Task`` as received from a data source.
    private struct RawTask: Decodable {
        let identifier: String
        let title: String
        let isComplete: Bool

        var model: Task {
            Task(identifier: identifier, title: title, isComplete: isComplete)
        }
    }

    /// Raw representation of a ``List`` as received from a data source.
    private struct RawList: Decodable {
        let identifier: String
        let title: String
        let tasks: [RawTask]

        var model: List {
            List(tasks: tasks.map(\.model), title: title, identifier: identifier)
        }
    }
}
