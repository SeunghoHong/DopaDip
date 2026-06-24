// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import ProjectDescription

// TCA를 프레임워크 산출물로 강제(@Shared·Store 등 동적 프레임워크로 묶기 위함).
// swift-navigation의 SPM traits는 .mise.toml의 ENABLE_ALL_TRAITS=1로 활성화한다.
//
// swift-navigation 2.10.1만 deployment target을 16.0으로 올린다 — 선언 min(iOS 13)에서
// Logger(iOS 14+)를 미가드로 써서 깨진다. Tuist는 패키지를 선언 min으로 빌드하므로(SwiftPM이
// 소비자 앱 min으로 빌드하는 것과 다름) 직접 올려준다. 언어모드는 navigation 선언대로 Swift 6 유지.
// swift-navigation: iOS 16 (Logger 미가드 회피). ComposableArchitecture: iOS 17
// (NavigationStackController가 iOS 17 전용이라 TCA 자기 min 16에서 참조 시 깨짐).
var targetSettings: [String: Settings] = [
    "ComposableArchitecture": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "17.0"]),
]
let navigationTargets = [
    "SwiftNavigation", "SwiftNavigationMacros", "SwiftUINavigation",
    "UIKitNavigation", "UIKitNavigationShim",
]
for name in navigationTargets {
    targetSettings[name] = .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "16.0"])
}

let packageSettings = PackageSettings(
    productTypes: [
        "ComposableArchitecture": .framework,
    ],
    targetSettings: targetSettings
)
#endif

let package = Package(
    name: "DopaDip",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
    ]
)
