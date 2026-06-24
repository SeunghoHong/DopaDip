# CLAUDE.md — DopaDip

Screen Time API로 집중을 돕는 iOS 앱. SwiftUI + TCA, Tuist, iOS 17, Swift 6.
설계는 아래 문서가 단일 진실원천 — 코딩 전에 관련 문서를 먼저 읽을 것.

## 문서 맵
- `CONTEXT.md` — 도메인 용어집(Focus Session·Shield·Blocked App). 새 용어 확정 시 갱신.
- `DESIGN.md` — 비주얼 토큰. iOS Clock 앱 다크 테마 기반.
- `docs/adr/0001~0003` — 되돌리기 어려운 결정(강제 메커니즘·블랙리스트·TCA 채택)과 그 이유.
- `Project.swift` / `Tuist/Package.swift` — 타겟 그래프·의존성. 주석에 가드레일 박혀 있음.

## 빌드 / 생성 / 실행
프로젝트는 Tuist가 생성한다(`*.xcodeproj`/`*.xcworkspace`는 git 무시). 소스/매니페스트만 커밋.

```bash
# 1) 프로젝트 생성 (Project.swift·Package.swift 바꾼 뒤 필수)
mise exec -- tuist install        # 의존성 resolve (Package.swift 바뀐 경우)
mise exec -- tuist generate       # *.xcworkspace 생성

# 2) 시뮬레이터 빌드 (서명 없이 — 컴파일 검증용)
xcodebuild -workspace DopaDip.xcworkspace -scheme DopaDip \
  -destination 'generic/platform=iOS Simulator' -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO -quiet

# 3) Xcode로 열기 (실기기 실행 — Screen Time은 실기기에서만 동작)
mise exec -- tuist generate --open
```

`ENABLE_ALL_TRAITS=1`은 `.mise.toml [env]`에 박혀 있어 `mise exec` 시 자동 주입된다(swift-navigation
SPM traits 활성화에 필수). 슬래시 커맨드 `/dd-generate`·`/dd-build`·`/dd-run`로도 호출 가능.

> 샌드박스 환경(예: 이 하니스)에서 `mise exec`가 `latest` 심링크 sandbox 충돌을 내면 실경로
> 바이너리로 우회: `~/.local/share/mise/installs/tuist/4.200.5/bin/tuist`. 일반 터미널에선 불필요.

## 의존성 가드레일 (건드리면 빌드 깨짐)
- **Tuist는 4.124+ 필요** (SPM traits 지원). `.mise.toml`에 `4.200.5` 핀. mise `latest`는 낡았음(4.55).
- Tuist는 외부 SPM 패키지를 "패키지 선언 min OS"로 빌드(SwiftPM은 소비자 min) → `Tuist/Package.swift`
  의 `targetSettings`로 **swift-navigation→iOS16**(Logger), **ComposableArchitecture→iOS17**
  (NavigationStackController) bump. **swift-perception는 건드리지 마**(Bindable 쉼이 iOS<17 전용).
- Xcode 26 / Swift 6.3 기준. TCA 1.26 / navigation 2.10 / perception 2.0.

## 아키텍처 (요약 — 상세는 ADR/CONTEXT)
- 타겟 4개: `DopaDip`(app, TCA) · `DopaDipKit`(shared framework, TCA 없음) ·
  `DeviceActivityMonitorExtension`(세션 종료 시 shield clear) · `ShieldConfigurationExtension`(차단 화면).
- 앱이 shield 직접 적용 + `DeviceActivitySchedule`로 자동 해제. App Group `group.com.dopadip`.
- TCA: 얇은 3-client(`screenTimeAuth`/`appShield`/`deviceActivity`) + reducer 오케스트레이션.
  크로스-프로세스 공유는 `@Shared`(App Group, `endDate`만). 익스텐션은 vanilla.
- 화면: `AppFeature`(권한 게이트) → `MainTab`(`Home`/`Settings`), `Home`은 idle/active 상태머신.

## 작업 규칙
- Swift/TCA 컨벤션은 `.claude/rules/swift.md`(Swift 파일 touch 시 자동 로드).
- "완료/통과" 주장 전 **위 시뮬레이터 빌드를 실제로 돌려 통과 확인**. 에러 출력 없이 단정 금지.
- Screen Time 동작(권한·shield·스케줄)은 시뮬레이터에서 안 됨 → 목 클라이언트로 UI 검증, 실기기로 동작 검증.
- 매니페스트(`Project.swift`/`Package.swift`) 수정 시 `tuist generate` 다시 (훅이 자동 처리).
