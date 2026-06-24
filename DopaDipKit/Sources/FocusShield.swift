import FamilyControls
import ManagedSettings

public extension ManagedSettingsStore.Name {
    /// Focus Session이 사용하는 단일 ManagedSettingsStore.
    /// (값타입 String 래퍼라 사실상 불변 — Apple이 Sendable 미표기라 unsafe로 명시.)
    nonisolated(unsafe) static let focus = Self("focus")
}

/// Focus Session 동안 선택한 앱에 Shield를 적용/해제한다.
/// 적용은 앱이(시작 버튼), 해제는 앱(포그라운드 종료) 또는 DeviceActivityMonitor 익스텐션
/// (백그라운드 종료)이 한다. 양쪽 모두 idempotent하게 호출해도 안전하다.
public enum FocusShield {
    private static var store: ManagedSettingsStore { ManagedSettingsStore(named: .focus) }

    /// 선택한 앱/카테고리에 shield 적용(blocklist 모델 — 고른 것만 차단).
    public static func apply(_ selection: FamilyActivitySelection) {
        let store = store
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil
            : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
    }

    /// 모든 shield 해제. 이미 해제된 상태에서 호출해도 안전.
    public static func clear() {
        store.clearAllSettings()
    }
}
