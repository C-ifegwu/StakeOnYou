import Foundation

// Thin adapter over existing FeatureFlagsService so Domain can depend on protocol
public protocol FeatureFlagsProviding {
    func isEnabled(_ key: String) -> Bool
    func variant(_ key: String) -> String?
}

public final class FeatureFlagsAdapter: FeatureFlagsProviding {
    private let service: FeatureFlagsService
    public init(service: FeatureFlagsService = .shared) { self.service = service }
    public func isEnabled(_ key: String) -> Bool { service.isEnabled(key) }
    public func variant(_ key: String) -> String? { service.getVariant(key) }
}


