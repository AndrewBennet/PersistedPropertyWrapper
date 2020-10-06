// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "PersistedPropertyWrapper",
    platforms: [.iOS(.v10), .macOS(.v10_13), .tvOS(.v10), .watchOS(.v2)],
    products: [
        .library(name: "PersistedPropertyWrapper", targets: ["PersistedPropertyWrapper"])
    ],
    targets: [
        .target(name: "PersistedPropertyWrapper"),
        .testTarget(
            name: "PersistedPropertyWrapperTests",
            dependencies: ["PersistedPropertyWrapper"]
        )
    ]
)
