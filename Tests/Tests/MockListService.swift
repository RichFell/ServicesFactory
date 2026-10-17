//
//  MockListService.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

@testable import ServicesFactory

/// A ``ListService`` stand-in used to register custom services with a factory.
final class MockListService: ListService {
    func allLists() async throws -> [List] {
        []
    }
}
