// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "swift-aws-sample",
    products: [
        .library(name: "Sample", targets: ["Sample"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", .upToNextMinor(from: "3.0.0")),
        .package(url: "https://github.com/kperson/swift-lambda-tools.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "Sample",
            dependencies: [
                "SwiftAWS",
                "SQS",
                "DynamoDB"
            ],
            path: "./Sources"
        ),
        .testTarget(
            name: "SampleTests",
            dependencies: [
                "Sample"
            ],
            path: "./Tests"
        )
    ]
)
