//
//  ListServiceImplementation.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// The default ``ListService`` implementation.
final class ListServiceImplementation: ListService {
    init() {}

    func allLists() async throws -> [List] {
        // No repository is wired up yet, so there are no lists to return.
        []
    }
}
