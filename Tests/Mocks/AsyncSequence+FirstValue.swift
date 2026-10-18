//
//  AsyncSequence+FirstValue.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

extension AsyncSequence {
    /// The first value the sequence yields, rethrowing the error it finishes with.
    ///
    /// - Throws: ``FirstValueError/finishedWithoutValue`` when the sequence ends with no values.
    func firstValue() async throws -> Element {
        for try await value in self {
            return value
        }
        throw FirstValueError.finishedWithoutValue
    }
}

enum FirstValueError: Error {
    case finishedWithoutValue
}
