// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "AsyncNetworkSessionDemo",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(
            name: "AsyncNetworkSessionDemo",
            targets: ["AsyncNetworkSessionDemo"]
        ),
    ],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "AsyncNetworkSessionDemo",
            dependencies: [
                .product(
                    name: "AsyncNetworkSession",
                    package: "AsyncNetworkSession"
                ),
            ]
        ),
    ]
)
