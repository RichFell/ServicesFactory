//
//  ServicesFactoryImplementationTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Testing
@testable import ServicesFactory

struct ServicesFactoryImplementationTests {
    @Test func serviceCreatesEventListServiceImplementationByDefault() async {
        let factory = ServicesFactoryImplementation()
        let service: EventListServiceImplementation = await factory.service(for: .eventList)
        #expect(service is EventListServiceImplementation)
    }

    @Test func serviceReusesCreatedInstance() async {
        let factory = ServicesFactoryImplementation()
        let first: EventListServiceImplementation = await factory.service(for: .eventList)
        let second: EventListServiceImplementation = await factory.service(for: .eventList)
        #expect(first === second)
    }

    @Test func registeredServiceIsReturned() async {
        let factory = ServicesFactoryImplementation()
        let mock = MockListService()
        await factory.register(mock, for: .eventList)
        let service: MockListService = await factory.service(for: .eventList)
        #expect(service === mock)
    }

    @Test func registeringReplacesPreviouslyCreatedService() async {
        let factory = ServicesFactoryImplementation()
        let _: EventListServiceImplementation = await factory.service(for: .eventList)
        let mock = MockListService()
        await factory.register(mock, for: .eventList)
        let service: MockListService = await factory.service(for: .eventList)
        #expect(service === mock)
    }

    @Test func factoriesDoNotShareServices() async {
        let firstFactory = ServicesFactoryImplementation()
        let secondFactory = ServicesFactoryImplementation()
        let first: EventListServiceImplementation = await firstFactory.service(for: .eventList)
        let second: EventListServiceImplementation = await secondFactory.service(for: .eventList)
        #expect(first !== second)
    }
}
