/// An optional attribute that the items of a ``List`` carry.
///
/// A list declares the fields its items use, so clients know which values to display or collect.
public enum ListField: String, Sendable, Hashable {
    /// Items have a ``ListItem/weight``, such as in a backpacking packing list.
    case weight
}
