//
//  ListField.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

/// An optional attribute that the items of a ``List`` carry.
///
/// A list declares the fields its items use, so clients know which values to display or collect.
/// Each field has a matching ``ListFieldValue`` case; add both together to support a new field.
public enum ListField: String, Sendable, Hashable {
    /// Items have a weight, such as in a backpacking packing list.
    case weight
    /// Items have a price, such as in a shopping list.
    case price
}
