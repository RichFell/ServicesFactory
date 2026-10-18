//
//  ChecklistItemRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import Foundation
import SQLiteData

/// The stored row for a ``ChecklistItem``, owned by one ``ChecklistComponentRecord``.
@Table("checklistItems")
struct ChecklistItemRecord: Equatable, Sendable {
    let id: String
    let componentID: String
    var title: String
    /// The item weight in grams, or `nil` when the item has no weight.
    var weightInGrams: Double?
    /// The item price as a decimal string, or `nil` when the item has no price.
    var price: String?
    var imageData: Data?
    var isCompleted: Bool
    /// The item's index within its component, preserving order.
    var position: Int

    /// Creates a row for `item` at `position` in the component `componentID`.
    init(
        _ item: ChecklistItem,
        componentID: String,
        position: Int
    ) {
        id = item.identifier
        self.componentID = componentID
        title = item.title
        weightInGrams = item.weight?.converted(to: .grams).value
        price = item.price.map { "\($0)" }
        imageData = item.imageData
        isCompleted = item.isCompleted
        self.position = position
    }

    /// Creates one row per item of each component of `checklist`, in order.
    static func records(for checklist: Checklist) -> [ChecklistItemRecord] {
        checklist.components.flatMap { component in
            component.items.enumerated().map { index, item in
                ChecklistItemRecord(item, componentID: component.identifier, position: index)
            }
        }
    }

    /// Rebuilds the public ``ChecklistItem``. An unreadable stored price is dropped.
    func makeItem() -> ChecklistItem {
        ChecklistItem(
            identifier: id,
            title: title,
            weight: weightInGrams.map { Measurement(value: $0, unit: .grams) },
            price: price.flatMap { Decimal(string: $0, locale: nil) },
            imageData: imageData,
            isCompleted: isCompleted
        )
    }

    /// Returns `items` with `itemID` moved to `position` and positions renumbered from zero.
    ///
    /// `position` is clamped to the valid range. Returns `items` unchanged (renumbered) when
    /// `itemID` is not among them.
    static func moving(_ itemID: String, to position: Int, in items: [ChecklistItemRecord]) -> [ChecklistItemRecord] {
        var ordered = items.sorted { $0.position < $1.position }
        if let index = ordered.firstIndex(where: { $0.id == itemID }) {
            let moved = ordered.remove(at: index)
            ordered.insert(moved, at: Swift.min(Swift.max(position, 0), ordered.count))
        }
        return ordered.enumerated().map { index, item in
            var renumbered = item
            renumbered.position = index
            return renumbered
        }
    }
}
