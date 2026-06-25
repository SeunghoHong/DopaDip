import SwiftUI

/// Clock 스타일 원형 액션 버튼(지름 76). Start=그린, 포기/취소=그레이.
struct CircularActionButton: View {
    let title: LocalizedStringKey
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
