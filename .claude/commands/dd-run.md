---
description: DopaDip — boot a simulator, install, and launch the app (UI shell only)
allowed-tools: Bash(mise:*), Bash(xcodebuild:*), Bash(xcrun:*)
---

UI 확인용으로 앱을 시뮬레이터에 띄운다(다크 테마·레이아웃 검증). Screen Time 권한·shield·스케줄은
시뮬레이터에서 동작하지 않으니, 그 동작 검증은 실기기(`tuist generate --open` 후 Xcode)로 한다.

순서:
1. 부팅된 iPhone 시뮬레이터 확보 — 없으면 `xcrun simctl list devices available`에서 iPhone 하나 골라 `boot`.
2. 그 시뮬레이터 destination으로 빌드:
   `xcodebuild -workspace DopaDip.xcworkspace -scheme DopaDip -destination 'platform=iOS Simulator,name=<골른 기기>' -configuration Debug build`
3. `.app` 산출물을 `xcrun simctl install booted <path>` 후 `xcrun simctl launch booted com.dopadip.app`.
4. 필요 시 `xcrun simctl io booted screenshot`로 화면 캡쳐해 확인.

실기기 실행은: `mise exec -- tuist generate --open` → Xcode에서 기기 선택 후 Run.
