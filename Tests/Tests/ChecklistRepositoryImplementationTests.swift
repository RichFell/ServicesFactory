//
//  ChecklistRepositoryImplementationTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct ChecklistRepositoryImplementationTests {
    @Test func allChecklistsDecodesFetchedData() async throws {
        let repository = ChecklistRepositoryImplementation { Data(#"[{"identifier":"a","title":"A","items":[]}]"#.utf8) }
        let checklists = try await repository.allChecklists().firstValue()
        #expect(checklists.count == 1)
    }

    @Test func allChecklistsPropagatesFetchErrors() async {
        struct FetchError: Error {}
        let repository = ChecklistRepositoryImplementation { throw FetchError() }
        await #expect(throws: FetchError.self) {
            try await repository.allChecklists().firstValue()
        }
    }
}
