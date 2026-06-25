# DopaDip

집중이 필요한 순간, 산만한 앱을 잠시 멀리 두도록 도와주는 iOS 앱이에요.
Apple **Screen Time API**(FamilyControls · DeviceActivity · ManagedSettings)로 내가 고른 앱만 차단해요.

> **포커스 세션(Focus Session)** — 집중할 시간을 정해 시작하면, 고른 앱이 그동안 차단되고(Shield)
> 세션이 끝나면 스스로 풀려요. iOS 시계 앱의 타이머를 떠올리면 돼요.

## 주요 기능 (MVP)

- **포커스 세션** — 카운트다운 휠을 돌려 1분부터 60분까지 정하고, 한 번에 한 세션만 진행해요.
- **앱 차단** — `FamilyActivityPicker`로 고른 앱만 차단해요(차단 앱, blocklist). DopaDip은 막지 않으니까,
  집중하는 중에도 앱을 열어 세션을 끝낼 수 있어요.
- **자동 해제** — 세션이 끝나면 앱이 Shield를 직접 풀고, `DeviceActivitySchedule`이 백그라운드에서도
  정시에 풀어 줘요.
- **차단 화면** — 차단한 앱을 열면 "집중 중 · 남은 N분"을 보여 주는 다크 화면이 떠요.
- **집중 링** — 진행 중에는 원형 진행 링과 큰 카운트다운으로 남은 시간을 보여 줘요.

### 로드맵 (v2)
사용량 리포트, 여러 프로파일, 세션 히스토리와 스트릭을 준비하고 있어요.

## 기술 스택

| 영역 | 선택 |
|---|---|
| UI | SwiftUI (iOS 17+, 다크 전용) |
| 아키텍처 | The Composable Architecture (TCA) — 앱 본체. 익스텐션은 vanilla |
| 시스템 | Screen Time API (FamilyControls · DeviceActivity · ManagedSettings) |
| 프로젝트 생성 | Tuist (`Project.swift`) |
| 언어 | Swift 6 (strict concurrency) |
| 도구 관리 | mise |

비주얼 토큰과 디자인 시스템은 [`DESIGN.md`](DESIGN.md)에 정리해 뒀어요.

## 요구 사항

- **Xcode 26+**, **Tuist 4.124+**(SPM traits를 지원해요 — `.mise.toml`에 핀으로 고정).
- 타깃 **iOS 17.0+**.
- **실기기에서 동작해요**: Screen Time(권한·Shield·스케줄)은 실기기에서만 돌아가요.
  시뮬레이터에서는 목 클라이언트로 UI를 확인할 수 있어요.
- App Store에 올릴 때는 Apple **Family Controls (Distribution)** entitlement 승인이 필요해요.
  개발과 TestFlight 단계에서는 필요 없어요.

## 시작하기

```bash
# 1) 프로젝트 생성 (소스/매니페스트만 git에 있고 .xcodeproj/.xcworkspace는 Tuist가 생성)
mise exec -- tuist install      # 의존성 resolve
mise exec -- tuist generate     # DopaDip.xcworkspace 생성

# 2) 시뮬레이터 빌드 (컴파일 검증)
xcodebuild -workspace DopaDip.xcworkspace -scheme DopaDip \
  -destination 'generic/platform=iOS Simulator' -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO

# 3) 테스트
xcodebuild test -workspace DopaDip.xcworkspace -scheme DopaDip \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# 4) 실기기 실행 (Screen Time 동작 확인)
mise exec -- tuist generate --open    # Xcode에서 기기 선택 후 Run
```

`ENABLE_ALL_TRAITS=1`은 `.mise.toml [env]`에 박혀 있어서 `mise exec`을 쓰면 자동으로 주입돼요
(swift-navigation의 SPM traits를 켜는 데 필요해요). Claude Code에서는 슬래시 커맨드 `/dd-generate`·`/dd-build`·
`/dd-run`으로도 부를 수 있어요.

## 프로젝트 구조

```
DopaDip/
├── DopaDip/Sources/                       # 앱 (TCA)
│   ├── DopaDipApp.swift, AppFeature.swift  # 진입점 + 권한 게이트 라우팅
│   ├── Design/                             # Palette·Typography·Components(FocusRing·DurationWheel…)
│   ├── Dependencies/                       # screenTimeAuth·appShield·deviceActivity·focusSession 클라이언트
│   └── Feature/                            # Permission·MainTab·Home·Settings
├── DopaDipKit/Sources/                     # 공유 framework (TCA 없음, 앱+익스텐션 공용)
├── DeviceActivityMonitorExtension/Sources/ # 세션 종료 시 Shield 해제(백스톱)
├── ShieldConfigurationExtension/Sources/   # 커스텀 차단 화면
├── DopaDipTests/Sources/                   # HomeFeature 상태머신 TestStore 테스트
├── Project.swift / Tuist/Package.swift     # Tuist 매니페스트
└── DESIGN.md / CLAUDE.md
```

앱은 `DopaDipKit`과 두 익스텐션, 그리고 `ComposableArchitecture`에 기대고, 익스텐션은 `DopaDipKit`만 써요.
프로세스끼리 나누는 값은 App Group `group.com.dopadip`에 담는데, 세션 종료 시각 하나만 오가요.

## 디자인

iOS **시계 앱(타이머 탭)**의 비주얼 언어를 따랐어요 — 순black 캔버스, 얇고 큰 숫자, 휠 피커, 원형 액션 버튼,
floating 탭바. 액센트는 세 가지만 써요: 오렌지(브랜드·진행) · 그린(시작) · 그레이(보조). 자세한 내용은
[`DESIGN.md`](DESIGN.md)에 있어요.

## 상태

MVP는 다 만들었어요 — 시뮬레이터 빌드와 테스트 6개가 green이고, UI 렌더도 확인했어요.
Screen Time 실동작은 지금 실기기에서 검증하고 있어요.
