// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AnotherLife",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AnotherLife",
            targets: ["AnotherLife"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
    ],
    targets: [
        .target(
            name: "AnotherLife",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
            ]
        ),
    ]
)
