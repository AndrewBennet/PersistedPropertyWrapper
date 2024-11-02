// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "PersistedPropertyWrapper",
    platforms: [.iOS(.v14), .macOS(.v11), .tvOS(.v14), .watchOS(.v7)],
    products: [
        .library(name: "PersistedPropertyWrapper", targets: ["PersistedPropertyWrapper"])
    ],
    targets: [
        .target(name: "PersistedPropertyWrapper"),
        .testTarget(
            name: "PersistedPropertyWrapperTests",
            dependencies: ["PersistedPropertyWrapper"]
        )
    ],
    swiftLanguageModes: [.v6]
)
