/// An event associated with a ``List``.
public struct Event: Sendable {
    /// The unique identifier of the event.
    public let identifier: String
    /// The display title of the event.
    public let title: String
    /// The list the event is using.
    public let list: List
    /// Whether the event has been completed.
    public let isComplete: Bool

    /// Creates an event with the given identifier, title, list, and completion state.
    public init(identifier: String, title: String, list: List, isComplete: Bool) {
        self.identifier = identifier
        self.title = title
        self.list = list
        self.isComplete = isComplete
    }
}
