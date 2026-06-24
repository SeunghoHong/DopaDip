import SwiftUI

/// Clock 스타일 원형 액션 버튼(지름 76). Start=그린, 포기/취소=그레이.
struct CircularActionButton: View {
    let title: String
    var fill: Color = Palette.actionStart
    var labelColor: Color = .black
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typo.buttonLabel)
                .foregroundStyle(labelColor)
                .frame(width: 76, height: 76)
                .background(fill, in: .circle)
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

/// 누르면 scale(0.95) — DESIGN.md의 시스템 마이크로 인터랙션.
struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
