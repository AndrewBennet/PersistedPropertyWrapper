// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "PersistedPropertyWrapper",
    platforms: [.iOS(.v11)],
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
