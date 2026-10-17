//
//  ListItemLinkRecordTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Testing
@testable import ServicesFactory

struct ListItemLinkRecordTests {
    private let links = [
        ListItemLinkRecord(listID: "l", itemID: "a", position: 0),
        ListItemLinkRecord(listID: "l", itemID: "b", position: 1),
        ListItemLinkRecord(listID: "l", itemID: "c", position: 2)
    ]

    private func order(_ itemID: String, to position: Int) -> [String] {
        ListItemLinkRecord.moving(itemID, to: position, in: links).map(\.itemID)
    }

    @Test func movesItemForwardAndRenumbers() {
        let moved = ListItemLinkRecord.moving("a", to: 2, in: links)

        #expect(moved.map(\.itemID) == ["b", "c", "a"])
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

    @Test func recordsForListFollowItemOrder() {
        let list = List(identifier: "l", items: [ListItem(identifier: "x", name: "X")])

        #expect(ListItemLinkRecord.records(for: list) == [ListItemLinkRecord(listID: "l", itemID: "x", position: 0)])
    }
}
