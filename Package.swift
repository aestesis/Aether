// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Aether",
    products: [
        .library(name: "Aether",targets: ["Aether"])
    ],
    dependencies: [
        .package(url: "https://github.com/aestesis/Uridium.git", from:"0.0.3")
    ],
    targets: [
        .target(name: "Aether",dependencies: []),
    ]
)
