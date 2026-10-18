//
//  ChecklistItemRecordTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct ChecklistItemRecordTests {
    private let items = ["a", "b", "c"].enumerated().map { index, id in
        ChecklistItemRecord(ChecklistItem(identifier: id, title: id.uppercased()), componentID: "c", position: index)
    }

    private func order(_ itemID: String, to position: Int) -> [String] {
        ChecklistItemRecord.moving(itemID, to: position, in: items).map(\.id)
    }

    @Test func movesItemForwardAndRenumbers() {
        let moved = ChecklistItemRecord.moving("a", to: 2, in: items)

        #expect(moved.map(\.id) == ["b", "c", "a"])
        #expect(moved.map(\.position) == [0, 1, 2])
    }

    @Test func movesItemBackward() {
        #expect(order("c", to: 0) == ["c", "a", "b"])
    }

    @Test func clampsPositionToBounds() {
        #expect(order("a", to: 99) == ["b", "c", "a"])
        #expect(order("c", to: -5) == ["c", "a", "b"])
    }

    @Test func leavesOrderAloneForUnknownItem() {
        #expect(order("missing", to: 0) == ["a", "b", "c"])
    }

    @Test func unreadablePriceIsDropped() {
        var record = items[0]
        record.price = "free"

        #expect(record.makeItem().price == nil)
    }
}
