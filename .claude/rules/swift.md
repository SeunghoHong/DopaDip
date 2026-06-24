---
description: Swift 6 / TCA / Screen Time conventions for DopaDip
paths: ["**/*.swift"]
---

# Swift / TCA 규칙 (DopaDip)

## 스타일
- for 루프 대신 고차 함수(map/compactMap/filter/forEach). 한 줄 120자. Dictionary는 가능한 한 줄.
- guard/if let: 한 줄 가능하면 `else`도 같은 줄, 아니면 다음 줄로. guard 뒤 한 줄 띄움.
- **의미 없는 이름 금지**: `Manager`/`Helper`/`Util(s)`/`Handler`/`Wrapper`/`Processor`/`Common`/`Base`/
  `Service`·`Data`·`Info` 단독. 동사+명사 또는 도메인+역할로(`SignupRateLimiter`, `episodePlaybackCoordinator`).
  이름이 안 떠오르면 타입이 일을 너무 많이 함 → 분리.

## TCA
- 리듀서는 `@Reducer` + `@ObservableState`. 부수효과는 `Effect`, 시스템 호출은 `@Dependency` 클라이언트로.
- 클라이언트는 시스템 API와 1:1로 얇게(`screenTimeAuth`/`appShield`/`deviceActivity`). 오케스트레이션은 reducer.
- 클라이언트는 `DependencyClient`로 정의하고 `liveValue`/`testValue`/`previewValue` 제공 — 시뮬레이터·프리뷰는
  목으로 돌린다(Screen Time은 실기기 전용이라 목 DI가 개발 루프의 핵심).
- 크로스-프로세스 상태는 `@Shared`(App Group). 익스텐션은 TCA 안 쓰고 `DopaDipKit`의 평문 접근으로 같은 값 읽음.
- 상태 전이 테스트는 `TestStore`로 결정적으로.

## Swift 6 동시성
- 앱 본체는 Swift 6 언어모드(strict concurrency). `@MainActor`·`Sendable` 경계 명시.
- Screen Time 토큰(`ApplicationToken` 등)·`ManagedSettingsStore`·`DeviceActivityCenter`의 isolation 주의.
- 의존성(TCA 등)은 Package.swift에서 별도 언어모드로 빌드 — 건드리지 말 것.

## 익스텐션 (별도 프로세스)
- `DeviceActivityMonitor`/`ShieldConfiguration` 익스텐션은 앱의 TCA store 못 씀. 공유는 App Group + `DopaDipKit`.
- 익스텐션 코드는 가볍게. 무거운 로직은 `DopaDipKit`로 빼서 앱·익스텐션 공유.
