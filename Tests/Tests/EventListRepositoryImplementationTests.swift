//
//  EventListRepositoryImplementationTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct EventListRepositoryImplementationTests {
    @Test func allListsDecodesFetchedData() async throws {
        let repository = EventListRepositoryImplementation { Data(#"[{"identifier":"a","title":"A","items":[]}]"#.utf8) }
        let lists = try await repository.allLists().firstValue()
        #expect(lists.count == 1)
    }

    @Test func allEventsIsEmptyForRawDataSource() async throws {
        let repository = EventListRepositoryImplementation { Data() }
        #expect(try await repository.allEvents().firstValue().isEmpty)
    }

    @Test func allEventRunsIsEmptyForRawDataSource() async throws {
        let repository = EventListRepositoryImplementation { Data() }
        #expect(try await repository.allEventRuns().firstValue().isEmpty)
    }

    @Test func allListsPropagatesFetchErrors() async {
        struct FetchError: Error {}
        let repository = EventListRepositoryImplementation { throw FetchError() }
        await #expect(throws: FetchError.self) {
            try await repository.allLists().firstValue()
        }
    }
}
