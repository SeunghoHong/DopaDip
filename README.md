# DopaDip

아이폰 사용을 스스로 제약해 업무·공부에 집중하도록 돕는 iOS 앱.
Apple **Screen Time API**(FamilyControls / DeviceActivity / ManagedSettings)로 산만한 앱을
차단한다.

> 핵심 모델 — **Focus Session**: 사용자가 길이를 정해 시작하면, 고른 앱이 그 시간 동안 차단(Shield)되고
> 끝나면 자동 해제된다. iOS Clock 앱의 타이머처럼 동작한다.

## 주요 기능 (MVP)

- **포커스 세션** — countDownTimer 휠로 1~60분 설정, 단일 타임드 블록.
- **앱 차단(blocklist)** — `FamilyActivityPicker`로 고른 산만한 앱만 Shield. DopaDip 자신은 안 막혀
  앱 안에서 언제든 종료 가능.
- **자동 종료** — 앱이 Shield를 직접 적용하고, `DeviceActivitySchedule`로 백그라운드에서도 정시 해제.
- **커스텀 차단 화면** — 차단 앱을 열면 "집중 중 · 남은 N분" 다크 화면.
- **집중 링** — 진행 중 화면은 원형 프로그레스 링 + 큰 카운트다운.

### 로드맵 (v2)
사용량 리포트 · 다중 프로파일 · 세션 히스토리/스트릭.

## 기술 스택

| 영역 | 선택 |
|---|---|
| UI | SwiftUI (iOS 17+, 다크 전용) |
| 아키텍처 | The Composable Architecture (TCA) — 앱 본체. 익스텐션은 vanilla |
| 시스템 | Screen Time API (FamilyControls · DeviceActivity · ManagedSettings) |
| 프로젝트 생성 | Tuist (`Project.swift`) |
| 언어 | Swift 6 (strict concurrency) |
| 도구 관리 | mise |

비주얼 토큰과 디자인 시스템은 [`DESIGN.md`](DESIGN.md) 참고.

## 요구 사항

- **Xcode 26+**, **Tuist 4.124+**(SPM traits 지원 — `.mise.toml`에 핀).
- 타깃 **iOS 17.0+**.
- **실기기 필수**: Screen Time(권한·Shield·스케줄)은 시뮬레이터에서 동작하지 않는다.
  시뮬레이터에선 목 클라이언트로 UI만 검증된다.
- App Store 배포 시 Apple **Family Controls (Distribution)** entitlement 승인 필요(개발·TestFlight은 불필요).

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

`ENABLE_ALL_TRAITS=1`은 `.mise.toml [env]`에 박혀 있어 `mise exec` 시 자동 주입된다
(swift-navigation의 SPM traits 활성화에 필수). Claude Code 슬래시 커맨드 `/dd-generate`·`/dd-build`·
`/dd-run`로도 호출 가능.

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

타겟 그래프: 앱 → `DopaDipKit` + 두 익스텐션 + `ComposableArchitecture`. 익스텐션 → `DopaDipKit`.
크로스-프로세스 공유는 App Group `group.com.dopadip`(세션 종료 시각만).

## 디자인

iOS **Clock 앱(Timer 탭)**의 비주얼 언어 — 순black 캔버스, 얇은 거대 숫자, 휠 피커, 원형 액션 버튼,
floating 탭바. 액센트 3색만: 오렌지(브랜드/진행) · 그린(시작) · 그레이(보조). 상세는 [`DESIGN.md`](DESIGN.md).

## 상태

MVP 구현 완료 — 시뮬레이터 빌드·6개 테스트 green, UI 렌더 확인. Screen Time 실동작은 실기기 검증 단계.
