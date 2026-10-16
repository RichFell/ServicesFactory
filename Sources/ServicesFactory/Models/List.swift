/// A list returned by a ``ListService``.
public struct List: Sendable {
    /// The tasks contained in the list.
    public let tasks: [Task]
    
    /// Title of the list
    public let title: String
    
    /// Identifier for list
    public let identifier: String

    /// Creates a list model with the given tasks.
    public init(
        tasks: [Task] = [],
        title: String = "",
        identifier: String = ""
    ) {
        self.tasks = tasks
        self.title = title
        self.identifier = identifier
    }
}
