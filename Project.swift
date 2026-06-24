import ProjectDescription

let appBundleID = "com.dopadip.app"
let appGroup = "group.com.dopadip"
let deploymentTargets: DeploymentTargets = .iOS("17.0")

let baseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.0",
    "CODE_SIGN_STYLE": "Automatic",
]

// Family Controls + App Group — app과 두 익스텐션이 공유한다.
let sharedEntitlements: [String: Plist.Value] = [
    "com.apple.developer.family-controls": .boolean(true),
    "com.apple.security.application-groups": .array([.string(appGroup)]),
]

func extensionInfoPlist(pointIdentifier: String, principalClass: String, displayName: String)
    -> InfoPlist {
    .extendingDefault(with: [
        "CFBundleDisplayName": .string(displayName),
        "NSExtension": .dictionary([
            "NSExtensionPointIdentifier": .string(pointIdentifier),
            "NSExtensionPrincipalClass": .string("$(PRODUCT_MODULE_NAME).\(principalClass)"),
        ]),
    ])
}

let project = Project(
    name: "DopaDip",
    organizationName: "DopaDip",
    options: .options(defaultKnownRegions: ["en", "ko"], developmentRegion: "ko"),
    settings: .settings(base: baseSettings),
    targets: [
        .target(
            name: "DopaDip",
            destinations: .iOS,
            product: .app,
            bundleId: appBundleID,
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("DopaDip"),
                "UILaunchScreen": .dictionary([:]),
            ]),
            sources: ["DopaDip/Sources/**"],
            resources: ["DopaDip/Resources/**"],
            entitlements: .dictionary(sharedEntitlements),
            dependencies: [
                .target(name: "DopaDipKit"),
                .target(name: "DeviceActivityMonitorExtension"),
                .target(name: "ShieldConfigurationExtension"),
                .external(name: "ComposableArchitecture"),
            ]
        ),
        .target(
            name: "DopaDipKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.dopadip.DopaDipKit",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: ["DopaDipKit/Sources/**"],
            dependencies: []
        ),
        .target(
            name: "DeviceActivityMonitorExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "\(appBundleID).DeviceActivityMonitor",
            deploymentTargets: deploymentTargets,
            infoPlist: extensionInfoPlist(
                pointIdentifier: "com.apple.deviceactivity.monitor-extension",
                principalClass: "FocusSessionMonitor",
                displayName: "DopaDip Monitor"
            ),
            sources: ["DeviceActivityMonitorExtension/Sources/**"],
            entitlements: .dictionary(sharedEntitlements),
            dependencies: [
                .target(name: "DopaDipKit"),
            ]
        ),
        .target(
            name: "ShieldConfigurationExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "\(appBundleID).ShieldConfiguration",
            deploymentTargets: deploymentTargets,
            infoPlist: extensionInfoPlist(
                pointIdentifier: "com.apple.ManagedSettingsUI.shield-configuration-service",
                principalClass: "FocusShieldConfiguration",
                displayName: "DopaDip Shield"
            ),
            sources: ["ShieldConfigurationExtension/Sources/**"],
            resources: ["ShieldConfigurationExtension/Resources/**"],
            entitlements: .dictionary(sharedEntitlements),
            dependencies: [
                .target(name: "DopaDipKit"),
            ]
        ),
        .target(
            name: "DopaDipTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(appBundleID).tests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: ["DopaDipTests/Sources/**"],
            dependencies: [
                .target(name: "DopaDip"),
            ]
        ),
    ]
)
