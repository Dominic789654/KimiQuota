// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KimiQuota",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "KimiQuota", targets: ["KimiQuota"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "KimiQuota",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
