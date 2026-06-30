# TODO

## (완료) 권한 라우팅 cold launch race — 로딩 화면 게이트로 수정
`feat/loading-screen-auth-gate`에서 구현. `ScreenTimeAuthClient.statusUpdates`(AsyncStream) 추가로
권한 상태를 관찰하고, 라우팅 트리거를 `AppFeature.loadingFinished`(Lottie 1회 재생 종료)로 옮겼다.
재생시간이 늦게 도착하는 `.approved`를 흡수해 콜드런치 race를 해소한다. 첫 화면은 `LoadingView`(Lottie).

### 남은 보강 (필요 시)
- Lottie 재생시간이 권한 settle(~100ms)보다 짧으면 종료 시 `.notDetermined`라 permission로 갈 수 있다.
  스플래시 길이면 무관. 너무 짧은 애니메이션을 쓰게 되면 종료 후 0.5초 grace 타이머를 덧대 hardening.
