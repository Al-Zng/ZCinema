// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ZCinema",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "ZCinema",
            dependencies: ["SwiftSoup"]
        )
    ]
)
