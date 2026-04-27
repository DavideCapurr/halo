// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "HaloShared",
  platforms: [.iOS(.v17), .macOS(.v12)],
  products: [
    .library(name: "HaloShared", targets: ["HaloShared"])
  ],
  targets: [
    .target(name: "HaloShared", path: "Sources/HaloShared"),
    .testTarget(name: "HaloSharedTests", dependencies: ["HaloShared"], path: "Tests/HaloSharedTests")
  ]
)
