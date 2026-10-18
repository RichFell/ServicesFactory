//
//  EventListBuilder.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation

/// Decodes raw list data into ``List`` models.
struct EventListBuilder: Sendable {

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
        let price: Decimal?

        var model: ListItem {
            var values: [ListField: ListFieldValue] = [:]
            if let weightInGrams {
                values[.weight] = .weight(Measurement(value: weightInGrams, unit: .grams))
            }
            if let price {
                values[.price] = .price(price)
            }
            return ListItem(identifier: identifier, name: name, values: values)
        }
    }

    /// Raw representation of a ``ListSection`` as received from a data source.
    private struct RawListSection: Decodable {
        let identifier: String
        let title: String?
        let items: [RawListItem]

        var model: ListSection {
            ListSection(identifier: identifier, title: title ?? "", items: items.map(\.model))
        }
    }

    /// Raw representation of a ``List`` as received from a data source.
    ///
    /// A list carries either `sections`, or a flat `items` array that becomes one untitled section.
    private struct RawList: Decodable {
        let identifier: String
        let title: String
        let fields: [String]?
        let sections: [RawListSection]?
        let items: [RawListItem]?

        var model: List {
            // Unknown fields from newer data sources are ignored.
            let fields = Set((fields ?? []).compactMap(ListField.init(rawValue:)))
            guard let sections else {
                return List(identifier: identifier, title: title, fields: fields, items: (items ?? []).map(\.model))
            }
            return List(identifier: identifier, title: title, fields: fields, sections: sections.map(\.model))
        }
    }
}
