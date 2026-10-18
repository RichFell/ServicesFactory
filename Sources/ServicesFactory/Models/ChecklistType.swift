//
//  ChecklistType.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

/// What a ``Checklist`` is for, which drives how clients display it.
public enum ChecklistType: String, Sendable, Hashable {
    /// A plain checklist. Items show only their title.
    case standard
    /// Items show their ``ChecklistItem/weight``, such as in a backpacking packing list.
    case weight
    /// Items show their ``ChecklistItem/price``, such as in a shopping list.
    case price
}
