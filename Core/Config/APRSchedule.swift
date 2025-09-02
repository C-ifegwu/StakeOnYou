import Foundation

// MARK: - APR Schedule
public struct APRTier: Equatable, Codable, Identifiable {
    public let id: String
    public let minPrincipal: Decimal
    public let maxPrincipal: Decimal?
    public let apr: Decimal // 0..1 annual
    public let compounding: Bool
    public let periodDays: Int // compounding period if compounding
    public init(id: String = UUID().uuidString, minPrincipal: Decimal, maxPrincipal: Decimal? = nil, apr: Decimal, compounding: Bool = false, periodDays: Int = 1) {
        self.id = id
        self.minPrincipal = minPrincipal
        self.maxPrincipal = maxPrincipal
        self.apr = apr
        self.compounding = compounding
        self.periodDays = periodDays
    }
}

public struct APRSchedule: Equatable, Codable {
    public let tiers: [APRTier]
    public init(tiers: [APRTier]) { self.tiers = tiers.sorted { $0.minPrincipal < $1.minPrincipal } }
    public func tier(for principal: Decimal) -> APRTier { tiers.last { principal >= $0.minPrincipal && ($0.maxPrincipal == nil || principal <= $0.maxPrincipal!) } ?? tiers.first! }
}

public protocol APRScheduleProvider {
    func schedule() -> APRSchedule
}

public final class DefaultAPRScheduleProvider: APRScheduleProvider {
    private let scheduleValue: APRSchedule
    public init(schedule: APRSchedule = APRSchedule(tiers: [
        APRTier(minPrincipal: 0, maxPrincipal: 500, apr: 0.02, compounding: false),
        APRTier(minPrincipal: 500, maxPrincipal: 2_500, apr: 0.03, compounding: true, periodDays: 7),
        APRTier(minPrincipal: 2_500, maxPrincipal: nil, apr: 0.04, compounding: true, periodDays: 1)
    ])) { self.scheduleValue = schedule }
    public func schedule() -> APRSchedule { scheduleValue }
}


