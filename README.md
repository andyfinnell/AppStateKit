# AppStateKit

A Redux-like framework for building SwiftUI based apps. Influenced by Pointfree Co's Composable Architecture.

## Requirements

- Swift 5.7 or greater
- iOS/tvOS 15 or greater OR macOS 12 or greater

## Installation

Currently, AppStateKit is only available as a Swift Package.

### ...using a Package.swift file

Open the Package.swift file and edit it:

1. Add AppStateKit repo to the `dependencies` array.
1. Add AppStateKit as a dependency of the target that will use it

```Swift
// swift-tools-version:5.3

import PackageDescription

let package = Package(
  // ...snip...
  dependencies: [
    .package(url: "https://github.com/andyfinnell/AppStateKit.git", from: "0.0.1")
  ],
  targets: [
    .target(name: "MyTarget", dependencies: ["AppStateKit"])
  ]
)
```

Then build to pull down the dependencies:

```Bash
$ swift build
```

### ...using Xcode

Use the Swift Packages tab on the project to add AppStateKit:

1. Open the Xcode workspace or project that you want to add AppStateKit to
1. In the file browser, select the project to show the list of projects/targets on the right
1. In the list of projects/targets on the right, select the project
1. Select the "Swift Packages" tab
1. Click on the "+" button to add a package
1. In the "Choose Package Repository" sheet, search for  "https://github.com/andyfinnell/AppStateKit.git"
1. Click "Next"
1. Choose the version rule you want
1. Click "Next"
1. Choose the target you want to add AppStateKit to
1. Click "Finish"
