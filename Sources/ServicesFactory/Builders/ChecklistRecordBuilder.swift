//
//  ChecklistRecordBuilder.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation

/// Maps between public ``Checklist`` models and their stored database records, and copies them.
struct ChecklistRecordBuilder: Sendable {

    init() {}

    /// Splits `checklist` into the rows that persist it.
    func records(for checklist: Checklist) -> ChecklistRecords {
        ChecklistRecords(
            checklist: ChecklistRecord(checklist),
            components: ChecklistComponentRecord.records(for: checklist),
            items: ChecklistItemRecord.records(for: checklist)
        )
    }

    /// Rebuilds public checklists from stored rows, in the order of `checklists`.
    ///
    /// Components are matched to their checklist by `checklistID` and items to their component by
    /// `componentID`, each ordered by `position`.
    func checklists(
        from checklists: [ChecklistRecord],
        components: [ChecklistComponentRecord],
        items: [ChecklistItemRecord]
    ) -> [Checklist] {
        let componentsByChecklist = Dictionary(grouping: components, by: \.checklistID)
        let itemsByComponent = Dictionary(grouping: items, by: \.componentID)
        return checklists.map { record in
            let built = (componentsByChecklist[record.id] ?? [])
                .sorted { $0.position < $1.position }
                .map { component in
                    ChecklistComponent(
                        identifier: component.id,
                        title: component.title,
                        items: (itemsByComponent[component.id] ?? [])
                            .sorted { $0.position < $1.position }
                            .map { $0.makeItem() }
                    )
                }
            return record.makeChecklist(components: built)
        }
    }

    /// Returns a copy of `checklist` titled `title`, with new identifiers throughout and nothing completed.
    ///
    /// - Parameters:
    ///   - checklist: The checklist to copy.
    ///   - title: The title of the copy.
    ///   - makeIdentifier: Supplies each new identifier.
    func copy(
        of checklist: Checklist,
        title: String,
        makeIdentifier: () -> String = { UUID().uuidString }
    ) -> Checklist {
        Checklist(
            identifier: makeIdentifier(),
            title: title,
            type: checklist.type,
            isFlatList: checklist.isFlatList,
            components: checklist.components.map { copy(of: $0, makeIdentifier: makeIdentifier) }
        )
    }

    /// Returns a copy of `component` with new identifiers for it and its items, and nothing completed.
    func copy(
        of component: ChecklistComponent,
        makeIdentifier: () -> String = { UUID().uuidString }
    ) -> ChecklistComponent {
        ChecklistComponent(
            identifier: makeIdentifier(),
            title: component.title,
            items: component.items.map { item in
                ChecklistItem(
                    identifier: makeIdentifier(),
                    title: item.title,
                    weight: item.weight,
                    price: item.price,
                    imageData: item.imageData
                )
            }
        )
    }
}

// MARK: - Nested Types

extension ChecklistRecordBuilder {
    /// The rows that together persist a single ``Checklist``.
    struct ChecklistRecords: Equatable, Sendable {
        let checklist: ChecklistRecord
        let components: [ChecklistComponentRecord]
        let items: [ChecklistItemRecord]
    }
}
