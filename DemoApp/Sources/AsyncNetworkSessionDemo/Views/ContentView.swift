import SwiftUI

struct ContentView: View {
    let serviceName: String

    var body: some View {
        ContentUnavailableView(
            "AsyncNetworkSession Demo",
            systemImage: "network",
            description: Text("Resolved service: \(serviceName)")
        )
    }
}

#Preview {
    ContentView(serviceName: "Demo network session")
}
