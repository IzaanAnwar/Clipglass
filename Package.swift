// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Clipglass",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "Clipglass", targets: ["Clipglass"])],
    targets: [
        .target(name: "ClipboardCore"),
        .systemLibrary(name: "CSQLite"),
        .target(name: "ClipboardMac", dependencies: ["ClipboardCore", "CSQLite"]),
        .executableTarget(name: "Clipglass", dependencies: ["ClipboardCore", "ClipboardMac"]),
        .testTarget(name: "ClipboardCoreTests", dependencies: ["ClipboardCore"]),
        .testTarget(name: "ClipboardMacTests", dependencies: ["ClipboardCore", "ClipboardMac"])
    ]
)
