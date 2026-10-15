import SwiftUI

struct MainView: View {
    @State private var viewModel = MainViewModel()

    var body: some View {
        ContentUnavailableView(
            "AsyncNetworkSession Demo",
            systemImage: "network",
            description: Text("Resolved service: \(viewModel.serviceName)")
        )
        .task {
            await viewModel.loadService()
        }
    }
}

#Preview {
    MainView()
}
