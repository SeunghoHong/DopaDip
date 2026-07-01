import DeviceActivity
import DopaDipKit

/// Focus Session 스케줄의 종료 시점에 호출되는 백스톱.
/// 앱이 백그라운드/종료 상태여도 여기서 Shield를 해제한다.
final class FocusSessionMonitor: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == .focusSession else { return }
        FocusShield.clear()
        FocusSessionStore.startDate = nil
        FocusSessionStore.endDate = nil
    }
}
