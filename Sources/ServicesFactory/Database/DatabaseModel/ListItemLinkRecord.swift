//
//  ListItemLinkRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

/// The stored row placing a ``ListItemRecord`` in a ``ListRecord`` at a display position.
///
/// Deleting a list or an item removes its links only; the other side is left in place.
@Table("listItemLinks")
struct ListItemLinkRecord: Equatable, Sendable {
    let listID: String
    let itemID: String
    /// The item's index in its list, preserving display order.
    var position: Int

    /// Creates one link per item of `list`, in order.
    static func records(for list: List) -> [ListItemLinkRecord] {
        list.items.enumerated().map { index, item in
            ListItemLinkRecord(listID: list.identifier, itemID: item.identifier, position: index)
        }
    }

    /// Returns `links` with `itemID` moved to `position` and positions renumbered from zero.
    ///
    /// `position` is clamped to the valid range. Returns `links` unchanged (renumbered) when
    /// `itemID` is not among them.
    static func moving(_ itemID: String, to position: Int, in links: [ListItemLinkRecord]) -> [ListItemLinkRecord] {
        var ordered = links.sorted { $0.position < $1.position }
        if let index = ordered.firstIndex(where: { $0.itemID == itemID }) {
            let moved = ordered.remove(at: index)
            ordered.insert(moved, at: Swift.min(Swift.max(position, 0), ordered.count))
        }
        return ordered.enumerated().map { index, link in
            ListItemLinkRecord(listID: link.listID, itemID: link.itemID, position: index)
        }
    }
}
