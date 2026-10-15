import AsyncNetworkSession
import SwiftUI

@main
struct AsyncNetworkSessionDemoApp: App {
    private let serviceName: String

    init() {
        let services = Services()
        services.register(DemoNetworkSessionService(), for: .asyncNetworkSession)

        let networkService: DemoNetworkSessionService = services.service(
            for: .asyncNetworkSession
        )
        serviceName = networkService.name
    }

    var body: some Scene {
        WindowGroup {
            ContentView(serviceName: serviceName)
        }
    }
}
