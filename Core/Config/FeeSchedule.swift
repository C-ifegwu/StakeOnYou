import Foundation

// MARK: - Fee Schedule
public struct FeeSchedule: Equatable, Codable {
    public var stakingFeePercent: Decimal // 0..1
    public var withdrawalFeePercent: Decimal // 0..1
    public var charitySplitOnFailurePercent: Decimal // 0..1 of forfeits to charity

    public init(
        stakingFeePercent: Decimal = 0.005,
        withdrawalFeePercent: Decimal = 0.0025,
        charitySplitOnFailurePercent: Decimal = 0.5
    ) {
        self.stakingFeePercent = stakingFeePercent
        self.withdrawalFeePercent = withdrawalFeePercent
        self.charitySplitOnFailurePercent = charitySplitOnFailurePercent
    }
}

// MARK: - Fee Buckets (for A/B)
public enum FeeBucket: String, Codable, CaseIterable { case A, B, C }

public protocol FeeScheduleProvider {
    func currentFeeSchedule(for bucket: FeeBucket) -> FeeSchedule
}

public final class DefaultFeeScheduleProvider: FeeScheduleProvider {
    private let schedules: [FeeBucket: FeeSchedule]
    public init(schedules: [FeeBucket: FeeSchedule] = [.A: FeeSchedule(), .B: FeeSchedule(stakingFeePercent: 0.0075), .C: FeeSchedule(stakingFeePercent: 0.0035)]) {
        self.schedules = schedules
    }
    public func currentFeeSchedule(for bucket: FeeBucket) -> FeeSchedule { schedules[bucket] ?? FeeSchedule() }
}


