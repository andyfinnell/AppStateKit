// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "AppStateKit",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AppStateKit",
            targets: ["AppStateKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        // Depend on the Swift 6.0 release of SwiftSyntax
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/andyfinnell/BaseKit.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "AppStateKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "AppStateKit",
            dependencies: ["AppStateKitMacros"]
        ),
        .testTarget(
            name: "AppStateKitTests",
            dependencies: ["AppStateKit", "BaseKit"]
        ),
        // A test target used to develop the macro implementation.
        .testTarget(
            name: "AppStateKitMacrosTests",
            dependencies: [
                "AppStateKitMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        
    ]
)
