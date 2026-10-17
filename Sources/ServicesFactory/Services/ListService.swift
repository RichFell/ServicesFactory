//
//  ListService.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A service that retrieves list models.
public protocol ListService: Service {
    /// Retrieves all available lists.
    func allLists() async throws -> [List]
}


