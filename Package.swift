// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FinderSideButtons",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "FinderSideButtons", targets: ["FinderSideButtons"])],
    targets: [
        .target(name: "NavigationCore"),
        .executableTarget(name: "FinderSideButtons", dependencies: ["NavigationCore"]),
        .testTarget(name: "NavigationCoreTests", dependencies: ["NavigationCore"])
    ]
)
