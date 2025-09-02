import Foundation
import Combine

@MainActor
final class CreateGoalViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var category: String = "Fitness & Exercise"
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @Published var stakeAmount: Decimal = 0
    @Published var enableStake: Bool = false
    @Published var isValid: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private var cancellables: Set<AnyCancellable> = []

    init() {
        // Simple validation
        Publishers.CombineLatest4($title, $description, $startDate, $endDate)
            .map { title, desc, start, end in
                !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                desc.count >= 10 &&
                start < end
            }
            .assign(to: &$isValid)
    }

    func submit() async {
        guard isValid else { return }
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        do {
            // Placeholder submission path
            try await Task.sleep(nanoseconds: 200_000_000)
            isSubmitting = false
            successMessage = "Goal created"
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
        }
    }
}


