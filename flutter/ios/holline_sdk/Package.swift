// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "holline_sdk",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "holline_sdk", targets: ["holline_sdk"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "holline_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
