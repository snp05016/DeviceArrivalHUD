// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeviceArrivalHUD",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DeviceArrivalHUD", targets: ["DeviceArrivalHUD"]),
        .library(name: "DeviceArrivalHUDLib", targets: ["DeviceArrivalHUDLib"])
    ],
    targets: [
        .target(
            name: "DeviceArrivalHUDLib",
            linkerSettings: [
                .linkedFramework("IOBluetooth"),
                .linkedFramework("IOKit"),
                .linkedFramework("GameController"),
                .linkedFramework("AVFoundation")
            ]
        ),
        .executableTarget(
            name: "DeviceArrivalHUD",
            dependencies: ["DeviceArrivalHUDLib"]
        ),
        .testTarget(
            name: "DeviceArrivalHUDTests",
            dependencies: ["DeviceArrivalHUDLib"]
        )
    ]
)
