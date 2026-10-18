//
//  ChecklistBuilder.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation

/// Decodes raw checklist data into ``Checklist`` models.
struct ChecklistBuilder: Sendable {

    init() {}

    /// Decodes `data` into an array of checklists.
    func decode(_ data: Data) throws -> [Checklist] {
        try JSONDecoder().decode([RawChecklist].self, from: data).map(\.model)
    }

    /// Raw representation of a ``ChecklistItem`` as received from a data source.
    private struct RawChecklistItem: Decodable {
        let identifier: String
        let title: String
        let weightInGrams: Double?
        let price: Decimal?
        /// Base64 encoded image.
        let imageData: Data?
        let isCompleted: Bool?

        var model: ChecklistItem {
            ChecklistItem(
                identifier: identifier,
                title: title,
                weight: weightInGrams.map { Measurement(value: $0, unit: .grams) },
                price: price,
                imageData: imageData,
                isCompleted: isCompleted ?? false
            )
        }
    }

    /// Raw representation of a ``ChecklistComponent`` as received from a data source.
    private struct RawChecklistComponent: Decodable {
        let identifier: String
        let title: String?
        let items: [RawChecklistItem]

        var model: ChecklistComponent {
            ChecklistComponent(identifier: identifier, title: title ?? "", items: items.map(\.model))
        }
    }

    /// Raw representation of a ``Checklist`` as received from a data source.
    ///
    /// A checklist carries either `components`, or a flat `items` array that becomes one flat checklist.
    private struct RawChecklist: Decodable {
        let identifier: String
        let title: String
        let type: String?
        let components: [RawChecklistComponent]?
        let items: [RawChecklistItem]?

        var model: Checklist {
            // An unknown type from a newer data source falls back to a standard checklist.
            let type = type.flatMap(ChecklistType.init(rawValue:)) ?? .standard
            guard let components else {
                return Checklist(identifier: identifier, title: title, type: type, items: (items ?? []).map(\.model))
            }
            return Checklist(
                identifier: identifier,
                title: title,
                type: type,
                isFlatList: false,
                components: components.map(\.model)
            )
        }
    }
}
