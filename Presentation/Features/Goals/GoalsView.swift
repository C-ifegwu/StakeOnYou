import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @Environment(\.router) private var router
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.goals.isEmpty {
                    emptyStateView
                } else {
                    goalsList
                }
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { router.navigateToCreateGoal() }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshGoals()
            }
            .sheet(item: $viewModel.presentedSheet) { sheet in
                sheetView(for: sheet)
            }
            .alert(item: $viewModel.presentedAlert) { alert in
                alertView(for: alert)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadGoals()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            // Stats Cards
            HStack(spacing: AppSpacing.sm) {
                StatCard(
                    title: "Active Goals",
                    value: "\(viewModel.activeGoalsCount)",
                    icon: "target",
                    color: .appPrimary
                )
                
                StatCard(
                    title: "Total Stakes",
                    value: viewModel.totalStakesFormatted,
                    icon: "dollarsign.circle",
                    color: .appSecondary
                )
            }
            
            // Quick Actions
            HStack(spacing: AppSpacing.sm) {
                QuickActionButton(
                    title: "Create Goal",
                    icon: "plus.circle",
                    action: { router.navigateToCreateGoal() }
                )
                
                QuickActionButton(
                    title: "Join Challenge",
                    icon: "person.3",
                    action: { router.navigateToJoinGroup() }
                )
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }
    
    // MARK: - Goals List
    private var goalsList: some View {
        List {
            // Active Goals Section
            Section("Active Goals") {
                ForEach(viewModel.activeGoals) { goal in
                    GoalRowView(goal: goal) {
                        router.navigate(to: .goalDetail(goal.id))
                    }
                }
            }
            
            // Completed Goals Section
            if !viewModel.completedGoals.isEmpty {
                Section("Completed Goals") {
                    ForEach(viewModel.completedGoals) { goal in
                        GoalRowView(goal: goal) {
                            router.navigate(to: .goalDetail(goal.id))
                        }
                    }
                }
            }
            
            // Overdue Goals Section
            if !viewModel.overdueGoals.isEmpty {
                Section("Overdue Goals") {
                    ForEach(viewModel.overdueGoals) { goal in
                        GoalRowView(goal: goal) {
                            router.navigate(to: .goalDetail(goal.id))
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading your goals...")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.appTextSecondary)
            
            Text("No Goals Yet")
                .font(.appTitle)
                .foregroundColor(.appTextPrimary)
            
            Text("Create your first goal to get started with staking and accountability.")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            Button(action: { router.navigateToCreateGoal() }) {
                Text("Create Your First Goal")
                    .font(.appLabel)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.appPrimary)
                    .cornerRadius(AppSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppSpacing.md)
    }
    
    // MARK: - Sheet Views
    @ViewBuilder
    private func sheetView(for sheet: GoalsSheetDestination) -> some View {
        switch sheet {
        case .createGoal:
            CreateGoalView()
        case .editGoal(let goalId):
            if let goal = viewModel.goals.first(where: { $0.id == goalId }) {
                EditGoalView(goal: goal)
            }
        case .goalVerification(let goalId):
            if let goal = viewModel.goals.first(where: { $0.id == goalId }) {
                GoalVerificationView(goal: goal)
            }
        }
    }
    
    // MARK: - Alert Views
    @ViewBuilder
    private func alertView(for alert: GoalsAlertDestination) -> some View {
        switch alert {
        case .error(let title, let message):
            Alert(
                title: Text(title),
                message: message.map { Text($0) },
                dismissButton: .default(Text("OK"))
            )
        case .confirmation(let title, let message, let action):
            Alert(
                title: Text(title),
                message: message.map { Text($0) },
                primaryButton: .default(Text("Confirm"), action: action),
                secondaryButton: .cancel()
            )
        case .goalCompletion(let title, let message):
            Alert(
                title: Text(title),
                message: message.map { Text($0) },
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Goal Row View
struct GoalRowView: View {
    let goal: Goal
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Goal Icon
                goalIcon
                
                // Goal Details
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(goal.title)
                        .font(.appLabel)
                        .fontWeight(.semibold)
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(2)
                    
                    Text(goal.description)
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                    
                    HStack(spacing: AppSpacing.sm) {
                        // Category Badge
                        CategoryBadge(category: goal.category)
                        
                        // Days Remaining
                        DaysRemainingBadge(goal: goal)
                        
                        // Stake Amount
                        if goal.stakeAmount > 0 {
                            StakeAmountBadge(amount: goal.stakeAmount, currency: goal.stakeCurrency)
                        }
                    }
                }
                
                Spacer()
                
                // Status Indicator
                statusIndicator
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var goalIcon: some View {
        ZStack {
            Circle()
                .fill(goal.category.color.opacity(0.1))
                .frame(width: 50, height: 50)
            
            Image(systemName: goal.category.icon)
                .font(.title2)
                .foregroundColor(goal.category.color)
        }
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(goal.status.color)
            .frame(width: 12, height: 12)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(value)
                        .font(.appTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.appTextPrimary)
                    
                    Text(title)
                        .font(.appLabel)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .cornerRadius(AppSpacing.sm)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.appLabel)
                
                Text(title)
                    .font(.appLabel)
                    .fontWeight(.medium)
            }
            .foregroundColor(.appPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.appPrimary.opacity(0.1))
            .cornerRadius(AppSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let category: GoalCategory
    
    var body: some View {
        Text(category.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(category.color)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background(category.color.opacity(0.1))
            .cornerRadius(AppSpacing.xxs)
    }
}

// MARK: - Days Remaining Badge
struct DaysRemainingBadge: View {
    let goal: Goal
    
    var body: some View {
        let daysRemaining = goal.daysRemaining
        let isOverdue = goal.isOverdue
        
        Text(isOverdue ? "Overdue" : "\(daysRemaining) days")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(isOverdue ? .appError : .appTextSecondary)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background((isOverdue ? Color.appError : Color.appTextSecondary).opacity(0.1))
            .cornerRadius(AppSpacing.xxs)
    }
}

// MARK: - Stake Amount Badge
struct StakeAmountBadge: View {
    let amount: Decimal
    let currency: String
    
    var body: some View {
        Text("\(currency) \(amount, specifier: "%.2f")")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.appSuccess)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background(Color.appSuccess.opacity(0.1))
            .cornerRadius(AppSpacing.xxs)
    }
}

// MARK: - Preview
struct GoalsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsView()
            .environment(\.router, AppRouter())
    }
}
