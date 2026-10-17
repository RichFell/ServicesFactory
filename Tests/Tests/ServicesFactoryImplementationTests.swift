import Testing
@testable import ServicesFactory

struct ServicesFactoryImplementationTests {
    @Test func serviceCreatesListServiceImplementationByDefault() async {
        let factory = ServicesFactoryImplementation()
        let service: ListServiceImplementation = await factory.service(for: .list)
        #expect(service is ListServiceImplementation)
    }

    @Test func serviceReusesCreatedInstance() async {
        let factory = ServicesFactoryImplementation()
        let first: ListServiceImplementation = await factory.service(for: .list)
        let second: ListServiceImplementation = await factory.service(for: .list)
        #expect(first === second)
    }

    @Test func registeredServiceIsReturned() async {
        let factory = ServicesFactoryImplementation()
        let mock = MockListService()
        await factory.register(mock, for: .list)
        let service: MockListService = await factory.service(for: .list)
        #expect(service === mock)
    }

    @Test func registeringReplacesPreviouslyCreatedService() async {
        let factory = ServicesFactoryImplementation()
        let _: ListServiceImplementation = await factory.service(for: .list)
        let mock = MockListService()
        await factory.register(mock, for: .list)
        let service: MockListService = await factory.service(for: .list)
        #expect(service === mock)
    }

    @Test func factoriesDoNotShareServices() async {
        let firstFactory = ServicesFactoryImplementation()
        let secondFactory = ServicesFactoryImplementation()
        let first: ListServiceImplementation = await firstFactory.service(for: .list)
        let second: ListServiceImplementation = await secondFactory.service(for: .list)
        #expect(first !== second)
    }
}
