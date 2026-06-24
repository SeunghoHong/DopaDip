#!/usr/bin/env bash
# PostToolUse hook — Tuist 매니페스트가 바뀌면 Xcode 프로젝트를 다시 생성한다.
# Edit/Write 대상이 Project.swift / Tuist/Package.swift / Tuist.swift 일 때만 동작.
set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" \
  | /usr/bin/python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' \
  2>/dev/null || true)"

case "$file_path" in
  */Project.swift|*/Tuist/Package.swift|*/Tuist.swift) ;;
  *) exit 0 ;;
esac

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
# Package.swift 변경은 install(의존성 resolve)까지 필요.
case "$file_path" in
  */Package.swift) mise exec -- tuist install >/dev/null 2>&1 || true ;;
esac
if mise exec -- tuist generate --no-open >/dev/null 2>&1; then
  echo "↻ tuist generate 완료 ($(basename "$file_path") 변경 반영)"
fi
exit 0
