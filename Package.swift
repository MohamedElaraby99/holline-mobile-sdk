// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HollineSDK",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "HollineSDK", targets: ["HollineSDK"]),
    ],
    targets: [
        .target(name: "HollineSDK", path: "ios/Sources/HollineSDK"),
    ]
)
