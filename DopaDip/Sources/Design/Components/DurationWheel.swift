import SwiftUI
import UIKit

/// iOS Clock 타이머의 countDownTimer 휠. SwiftUI엔 네이티브가 없어 UIDatePicker를 래핑한다.
/// 하한 1분(테스트)·상한 60분은 호출부(시작 버튼)에서 검증한다.
struct DurationWheel: UIViewRepresentable {
    @Binding var duration: TimeInterval

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        picker.minuteInterval = 1
        picker.preferredDatePickerStyle = .wheels
        picker.overrideUserInterfaceStyle = .dark
        picker.countDownDuration = duration
        picker.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        context.coordinator.duration = $duration
        if picker.countDownDuration != duration {
            picker.countDownDuration = duration
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(duration: $duration)
    }

    @MainActor
    final class Coordinator: NSObject {
        var duration: Binding<TimeInterval>

        init(duration: Binding<TimeInterval>) {
            self.duration = duration
        }

        @objc func valueChanged(_ picker: UIDatePicker) {
            duration.wrappedValue = picker.countDownDuration
        }
    }
}
