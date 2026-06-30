import Lottie
import SwiftUI

/// 첫 로딩 화면. 가운데 워드마크를 보여주고, 끝나면 `onFinished`로 권한 라우팅을 트리거한다.
/// loading.json(Lottie)은 일단 숨겨두고 재생 길이만 로딩 유예로 쓴다 — 그 시간이 콜드런치
/// 권한 복원(race)을 흡수한다.
struct LoadingView: View {
    let onFinished: () -> Void

    private let animation = LottieAnimation.named("loading")
    @State private var didFinish = false

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            wordmark
        }
        // loading.json은 일단 표시하지 않고(hidden) 재생 길이만 로딩 유예로 쓴다. 끝나면 라우팅.
        .task {
            if let duration = animation?.duration {
                try? await Task.sleep(for: .seconds(duration))
            }
            finish()
        }
    }

    private var wordmark: some View {
        Image("dopadip-wordmark")
            .resizable()
            .scaledToFit()
            .frame(width: 240)
    }

    private func finish() {
        guard !didFinish else { return }

        didFinish = true
        onFinished()
    }
}
