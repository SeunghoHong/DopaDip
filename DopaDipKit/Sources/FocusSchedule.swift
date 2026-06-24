import DeviceActivity
import Foundation

public extension DeviceActivityName {
    /// Focus Session의 종료 시점을 백그라운드에서 강제하는 DeviceActivity.
    /// (값타입 String 래퍼라 사실상 불변 — Apple이 Sendable 미표기라 unsafe로 명시.)
    nonisolated(unsafe) static let focusSession = Self("focusSession")
}

/// Focus Session의 자동 종료를 위한 DeviceActivity 스케줄을 제어한다.
/// DeviceActivitySchedule은 최소 인터벌이 15분이라, 그 미만 세션은 스케줄을 걸지 않고
/// 앱 타이머(Effect)가 해제를 담당한다(테스트용 짧은 세션 시나리오).
public enum FocusSchedule {
    /// DeviceActivitySchedule이 신뢰성 있게 동작하는 최소 길이(초).
    public static let minimumScheduledDuration: TimeInterval = 15 * 60

    private static var center: DeviceActivityCenter { DeviceActivityCenter() }

    /// start ~ start+duration 구간 모니터링 시작. 길이가 최소치 미만이면 스케줄을 걸지 않고 false 반환.
    @discardableResult
    public static func start(
        from start: Date,
        duration: TimeInterval,
        calendar: Calendar = .current
    ) -> Bool {
        guard duration >= minimumScheduledDuration else { return false }
        let end = start.addingTimeInterval(duration)
        // 풀 날짜 성분으로 절대 시각 윈도우를 만든다. 시:분:초만 쓰면 자정을 넘기는
        // 세션(예: 23:50 시작 → 00:20 종료)에서 intervalEnd가 intervalStart보다 작아져 깨진다.
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(components, from: start),
            intervalEnd: calendar.dateComponents(components, from: end),
            repeats: false
        )
        do {
            try center.startMonitoring(.focusSession, during: schedule)
            return true
        } catch {
            return false
        }
    }

    /// 모니터링 중단. 진행 중이 아니어도 안전.
    public static func stop() {
        center.stopMonitoring([.focusSession])
    }
}
