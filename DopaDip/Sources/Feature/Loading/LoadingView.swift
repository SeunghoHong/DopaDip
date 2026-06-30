import Lottie
import SwiftUI

/// 첫 로딩 화면. Lottie를 1회 재생하고, 끝나면 `onFinished`로 권한 라우팅을 트리거한다.
/// 재생시간이 곧 콜드런치 권한 복원(race)을 흡수하는 유예 역할을 한다.
struct LoadingView: View {
    let onFinished: () -> Void

    private let animation = LottieAnimation.named("loading")
    @State private var didFinish = false

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            LottieView(animation: animation)
                .playing(loopMode: .playOnce)
                .animationDidFinish { _ in finish() }
        }
        // 번들에 애니메이션이 없으면(개발 중 미배치) 멈추지 않고 즉시 통과시킨다.
        .task { if animation == nil { finish() } }
    }

    private func finish() {
        guard !didFinish else { return }

        didFinish = true
        onFinished()
    }
}
