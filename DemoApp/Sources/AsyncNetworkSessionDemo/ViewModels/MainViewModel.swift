import AsyncNetworkSession
import Observation

@MainActor
@Observable
final class MainViewModel {
    private let services = Services()

    private(set) var serviceName = "Loading service…"

    func loadService() async {
        await services.register(
            DemoNetworkSessionService(),
            for: .asyncNetworkSession
        )

        let networkService: DemoNetworkSessionService = await services.service(
            for: .asyncNetworkSession
        )
        serviceName = networkService.name
    }
}
