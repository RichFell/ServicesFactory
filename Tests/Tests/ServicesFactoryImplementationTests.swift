//
//  ServicesFactoryImplementationTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Testing
@testable import ServicesFactory

struct ServicesFactoryImplementationTests {
    @Test func serviceCanBeRequestedByProtocolType() async {
        let factory = ServicesFactoryImplementation(databaseLocation: .inMemory)
        let service = await factory.service(for: .checklist) as ChecklistService
        #expect(service.type == .checklist)
    }

    @Test func serviceReusesCreatedInstance() async {
        let factory = ServicesFactoryImplementation(databaseLocation: .inMemory)
        let first: ChecklistServiceImplementation = await factory.service(for: .checklist)
        let second: ChecklistServiceImplementation = await factory.service(for: .checklist)
        #expect(first === second)
    }

    @Test func factoriesDoNotShareServices() async {
        let firstFactory = ServicesFactoryImplementation(databaseLocation: .inMemory)
        let secondFactory = ServicesFactoryImplementation(databaseLocation: .inMemory)
        let first: ChecklistServiceImplementation = await firstFactory.service(for: .checklist)
        let second: ChecklistServiceImplementation = await secondFactory.service(for: .checklist)
        #expect(first !== second)
    }
}
