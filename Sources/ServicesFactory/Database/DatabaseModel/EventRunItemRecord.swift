//
//  EventRunItemRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import SQLiteData

/// An item as it appeared in a snapshotted list when a run started.
///
/// Holds its own name and weight, so renaming or deleting the live item leaves the run unchanged.
@Table("eventRunItems")
struct EventRunItemRecord: Equatable, Sendable {
    let runID: String
    let listID: String
    /// The identifier of the live item this was copied from. Completions refer to it.
    let itemID: String
    var name: String
    /// The item weight in grams, or `nil` when the item has no weight.
    var weightInGrams: Double?
    /// The item's index within its list, preserving order.
    var position: Int

    /// Creates one row per item of each list in `run`, in order.
    static func records(for run: EventRun) -> [EventRunItemRecord] {
        run.lists.flatMap { list in
            list.items.enumerated().map { index, item in
                EventRunItemRecord(
                    runID: run.identifier,
                    listID: list.identifier,
                    itemID: item.identifier,
                    name: item.name,
                    weightInGrams: item.weight?.converted(to: .grams).value,
                    position: index
                )
            }
        }
    }

    /// Rebuilds the public ``ListItem``.
    func makeListItem() -> ListItem {
        ListItem(
            identifier: itemID,
            name: name,
            weight: weightInGrams.map { Measurement(value: $0, unit: .grams) }
        )
    }
}
