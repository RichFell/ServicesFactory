//
//  ListFieldValue.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation

/// The value of one ``ListField`` on a ``ListItem``.
///
/// Supporting a new field takes a new case here, a matching ``ListField`` case, and one line in
/// each of ``field`` and the storage conversions. No database migration is needed.
public enum ListFieldValue: Sendable, Hashable {
    /// The item's weight.
    case weight(Measurement<UnitMass>)
    /// The item's price, in the user's own currency.
    case price(Decimal)

    /// The field this value belongs to.
    public var field: ListField {
        switch self {
        case .weight: .weight
        case .price: .price
        }
    }

    /// The value as stored: grams for weight, a plain decimal string for price.
    var storedValue: String {
        switch self {
        case .weight(let weight): "\(weight.converted(to: .grams).value)"
        case .price(let price): "\(price)"
        }
    }

    /// Rebuilds a value from its stored form, or `nil` when `storedValue` can't be read as `field`.
    init?(field: ListField, storedValue: String) {
        switch field {
        case .weight:
            guard let grams = Double(storedValue) else { return nil }
            self = .weight(Measurement(value: grams, unit: .grams))
        case .price:
            guard let price = Decimal(string: storedValue, locale: nil) else { return nil }
            self = .price(price)
        }
    }
}
