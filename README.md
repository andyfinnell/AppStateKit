# AppStateKit

A Elm-like framework for building SwiftUI based apps. Influenced by Pointfree Co's 
The Composable Architecture, Redux, and Elm.

It changes at my whim, and is almost always in a state of a rewrite as I explore
new ideas. As a result, the most recent is `main`, not any tagged release.

Currently AppStateKit leverages Swift macros to build Elm-like Components and
automatically compose them together. Components combine the reducer and the view
together in one type, while keeping the reducer testable apart from the view.

## Requirements

- Swift 5.9 or greater
- iOS/tvOS 17 or greater OR macOS 14 or greater

## Installation

Currently, AppStateKit is only available as a Swift Package.

### ...using a Package.swift file

Open the Package.swift file and edit it:

1. Add AppStateKit repo to the `dependencies` array.
1. Add AppStateKit as a dependency of the target that will use it

```Swift
// swift-tools-version:5.9

import PackageDescription

let package = Package(
  // ...snip...
  dependencies: [
    .package(url: "https://github.com/andyfinnell/AppStateKit.git", branch: "main")
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
1. Choose the `main` branch rule
1. Click "Next"
1. Choose the target you want to add AppStateKit to
1. Click "Finish"
