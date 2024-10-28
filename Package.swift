// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "PersistedPropertyWrapper",
    platforms: [.iOS(.v13), .macOS(.v11), .tvOS(.v13), .watchOS(.v5)],
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
