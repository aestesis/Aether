// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Aether",
    products: [
        .library(name: "Aether",targets: ["Aether"])
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", from:"17.0.0"),
        .package(url: "https://github.com/aestesis/Uridium.git", from:"0.0.7")
    ],
    targets: [
        .target(name: "Aether",dependencies: ["Uridium","SwiftyJSON"]),
    ]
)
