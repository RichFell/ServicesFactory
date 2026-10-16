/// A task belonging to a ``List``.
public struct Task: Sendable {
    /// The unique identifier of the task.
    public let identifier: String
    /// The display title of the task.
    public let title: String
    /// Whether the task has been completed.
    public let isComplete: Bool

    /// Creates a task with the given identifier, title, and completion state.
    public init(identifier: String, title: String, isComplete: Bool) {
        self.identifier = identifier
        self.title = title
        self.isComplete = isComplete
    }
}
