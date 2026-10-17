//
//  ListBuilder.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation

/// Decodes raw list data into ``List`` models.
struct ListBuilder: Sendable {

    init() {}

    /// Decodes `data` into an array of lists.
    func decode(_ data: Data) throws -> [List] {
        try JSONDecoder().decode([RawList].self, from: data).map(\.model)
    }

    /// Raw representation of a ``ListItem`` as received from a data source.
    private struct RawListItem: Decodable {
        let identifier: String
        let name: String
        let weightInGrams: Double?

        var model: ListItem {
            ListItem(
                identifier: identifier,
                name: name,
                weight: weightInGrams.map { Measurement(value: $0, unit: .grams) }
            )
        }
    }

    /// Raw representation of a ``List`` as received from a data source.
    private struct RawList: Decodable {
        let identifier: String
        let title: String
        let fields: [String]?
        let items: [RawListItem]

        var model: List {
            List(
                identifier: identifier,
                title: title,
                // Unknown fields from newer data sources are ignored.
                fields: Set((fields ?? []).compactMap(ListField.init(rawValue:))),
                items: items.map(\.model)
            )
        }
    }
}
