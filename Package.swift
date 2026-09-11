// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "JiraLocalApp",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "JiraLocalApp",
            path: "Sources/JiraLocalApp"
        )
    ]
)
