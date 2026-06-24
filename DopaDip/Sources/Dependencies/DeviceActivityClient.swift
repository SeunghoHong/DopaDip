import ComposableArchitecture
import DopaDipKit
import Foundation

/// Focus Session 종료를 백그라운드에서 강제하는 DeviceActivity 스케줄 클라이언트(`FocusSchedule` 래핑).
@DependencyClient
struct DeviceActivityClient {
    /// start ~ start+duration 모니터링 시작. 길이가 15분 미만이면 스케줄을 걸지 않고 false.
    var start: @Sendable (_ from: Date, _ duration: TimeInterval) -> Bool = { _, _ in false }
    var stop: @Sendable () -> Void
}

extension DeviceActivityClient: DependencyKey {
    static let liveValue = DeviceActivityClient(
        start: { FocusSchedule.start(from: $0, duration: $1) },
        stop: { FocusSchedule.stop() }
    )
    static let testValue = DeviceActivityClient()
    static let previewValue = DeviceActivityClient(start: { _, _ in true }, stop: {})
}

extension DependencyValues {
    var deviceActivity: DeviceActivityClient {
        get { self[DeviceActivityClient.self] }
        set { self[DeviceActivityClient.self] = newValue }
    }
}
