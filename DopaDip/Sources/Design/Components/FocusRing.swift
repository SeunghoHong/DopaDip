import SwiftUI

/// active 세션의 원형 진행 링. 트랙은 흐린 흰색, 진행은 브랜드 오렌지(DESIGN.md).
struct FocusRing: View {
    /// 0~1 진행률.
    let progress: Double
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.ringTrack, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    Palette.accentBrand,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)
        }
    }
}
