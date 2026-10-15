import AsyncNetworkSession
import SwiftUI

struct ContentView: View {
    @State private var serviceName = "Loading service…"

    var body: some View {
        ContentUnavailableView(
            "AsyncNetworkSession Demo",
            systemImage: "network",
            description: Text("Resolved service: \(serviceName)")
        )
        .task {
            let services = Services()
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
}

#Preview {
    ContentView()
}
