/// A task belonging to a ``List``.
public struct Task: Sendable, Decodable {
    /// The unique identifier of the task.
    public let identifier: String
    /// The display title of the task.
    public let title: String

    /// Creates a task with the given identifier and title.
    public init(identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
    }
}
