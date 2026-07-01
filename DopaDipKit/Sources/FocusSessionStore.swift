import Foundation

/// Focus Session의 종료 시각을 App Group에 공유한다.
/// 앱은 `FocusSessionClient`(@Dependency)를 통해 쓰고, ShieldConfiguration 익스텐션은
/// "남은 시간" 계산을 위해 평문으로 직접 읽는다(익스텐션은 TCA 없음).
public enum FocusSessionStore {
    /// App Group UserDefaults 키. 앱의 @Shared와 반드시 일치시킨다.
    public static let endDateKey = "focusSessionEndDate"
    /// 세션 시작 시각 키. 진행률(경과/전체) 복원에 필요 — endDate만으론 전체 길이를 알 수 없다.
    public static let startDateKey = "focusSessionStartDate"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroup.identifier)
    }

    /// 세션 시작 시각. 진행 중이 아니면 nil.
    public static var startDate: Date? {
        get {
            guard let raw = defaults?.object(forKey: startDateKey) as? Double else { return nil }
            return Date(timeIntervalSinceReferenceDate: raw)
        }
        set {
            guard let defaults else { return }
            if let newValue {
                defaults.set(newValue.timeIntervalSinceReferenceDate, forKey: startDateKey)
            } else {
                defaults.removeObject(forKey: startDateKey)
            }
        }
    }

    /// 세션 종료 시각. 진행 중이 아니면 nil. (Double로 저장 — @Shared·익스텐션 양쪽 호환)
    public static var endDate: Date? {
        get {
            guard let raw = defaults?.object(forKey: endDateKey) as? Double else { return nil }
            return Date(timeIntervalSinceReferenceDate: raw)
        }
        set {
            guard let defaults else { return }
            if let newValue {
                defaults.set(newValue.timeIntervalSinceReferenceDate, forKey: endDateKey)
            } else {
                defaults.removeObject(forKey: endDateKey)
            }
        }
    }

    /// 기준 시각에서 세션 종료까지 남은 시간(초). 세션이 없거나 끝났으면 0.
    public static func remaining(at now: Date = Date()) -> TimeInterval {
        guard let endDate else { return 0 }
        return max(0, endDate.timeIntervalSince(now))
    }
}
