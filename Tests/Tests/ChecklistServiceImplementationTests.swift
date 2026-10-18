//
//  ChecklistServiceImplementationTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Testing
@testable import ServicesFactory

struct ChecklistServiceImplementationTests {
    private struct TestError: Error, Equatable {}

    private func makeService(_ repository: MockChecklistRepository) -> ChecklistServiceImplementation {
        ChecklistServiceImplementation(dependency: .init(localCache: repository))
    }

    @Test func allChecklistsReturnsNoChecklistsWhenCacheIsEmpty() async throws {
        let service = makeService(MockChecklistRepository())
        #expect(try await service.allChecklists().firstValue().isEmpty)
    }

    @Test func allChecklistsReturnsRepositoryChecklists() async throws {
        let checklist = Checklist(identifier: "pack", title: "Packing")
        let service = makeService(MockChecklistRepository(checklists: [checklist]))

        #expect(try await service.allChecklists().firstValue().map(\.identifier) == ["pack"])
    }

    @Test func allChecklistsPropagatesRepositoryError() async {
        let service = makeService(MockChecklistRepository(error: TestError()))

        await #expect(throws: TestError.self) {
            try await service.allChecklists().firstValue()
        }
    }
}
