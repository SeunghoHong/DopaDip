---
description: DopaDip — resolve deps and regenerate the Xcode project (Tuist)
allowed-tools: Bash(mise:*)
---

`Project.swift` 또는 `Tuist/Package.swift`를 바꾼 뒤 Xcode 프로젝트를 다시 생성한다.
다음을 실행하고 결과만 보고:

```bash
mise exec -- tuist install && mise exec -- tuist generate --no-open
```

샌드박스에서 `mise exec`가 막히면 실경로로 우회:
`~/.local/share/mise/installs/tuist/4.200.5/bin/tuist`.
