//
//  EventListServiceImplementationTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Testing
@testable import ServicesFactory

struct EventListServiceImplementationTests {
    private struct TestError: Error, Equatable {}

    private func makeService(_ repository: MockEventListRepository) -> EventListServiceImplementation {
        EventListServiceImplementation(dependency: .init(localCache: repository))
    }

    @Test func allListsReturnsNoListsWhenCacheIsEmpty() async throws {
        let service = makeService(MockEventListRepository())
        #expect(try await service.allLists().firstValue().isEmpty)
    }

    @Test func allListsReturnsRepositoryLists() async throws {
        let list = List(identifier: "pack", title: "Packing", fields: [], items: [])
        let service = makeService(MockEventListRepository(lists: [list]))

        #expect(try await service.allLists().firstValue().map(\.identifier) == ["pack"])
    }

    @Test func allEventsReturnsNoEventsWhenCacheIsEmpty() async throws {
        let service = makeService(MockEventListRepository())
        #expect(try await service.allEvents().firstValue().isEmpty)
    }

    @Test func allListsPropagatesRepositoryError() async {
        let service = makeService(MockEventListRepository(error: TestError()))

        await #expect(throws: TestError.self) {
            try await service.allLists().firstValue()
        }
    }

    @Test func allEventsPropagatesRepositoryError() async {
        let service = makeService(MockEventListRepository(error: TestError()))

        await #expect(throws: TestError.self) {
            try await service.allEvents().firstValue()
        }
    }
}
