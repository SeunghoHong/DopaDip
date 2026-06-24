---
description: DopaDip — build all targets for iOS Simulator (no signing) and report
allowed-tools: Bash(mise:*), Bash(xcodebuild:*)
---

시뮬레이터용으로 4타겟(app + 2 익스텐션 + DopaDipKit)을 빌드해 컴파일을 검증한다.
다음을 실행하고 **에러와 BUILD 결과만** 보고(전체 로그 금지):

```bash
mise exec -- tuist generate --no-open && \
xcodebuild -workspace DopaDip.xcworkspace -scheme DopaDip \
  -destination 'generic/platform=iOS Simulator' -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO -quiet 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

BUILD FAILED면 첫 에러부터 원인 분석. Screen Time 동작 자체는 시뮬레이터에서 검증 불가(실기기 필요).
