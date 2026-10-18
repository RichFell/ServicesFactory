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
        let service = await factory.service(for: .eventList) as EventListService
        #expect(service.type == .eventList)
    }

    @Test func serviceReusesCreatedInstance() async {
        let factory = ServicesFactoryImplementation(databaseLocation: .inMemory)
        let first: EventListServiceImplementation = await factory.service(for: .eventList)
        let second: EventListServiceImplementation = await factory.service(for: .eventList)
        #expect(first === second)
    }

    @Test func factoriesDoNotShareServices() async {
        let firstFactory = ServicesFactoryImplementation(databaseLocation: .inMemory)
        let secondFactory = ServicesFactoryImplementation(databaseLocation: .inMemory)
        let first: EventListServiceImplementation = await firstFactory.service(for: .eventList)
        let second: EventListServiceImplementation = await secondFactory.service(for: .eventList)
        #expect(first !== second)
    }
}
