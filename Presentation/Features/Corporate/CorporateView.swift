import SwiftUI

struct CorporateView: View {
    @StateObject private var viewModel = CorporateViewModel()
    @Environment(\.router) private var router
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.corporateAccounts.isEmpty {
                    emptyStateView
                } else {
                    corporateList
                }
            }
            .navigationTitle("Corporate")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { router.navigateToJoinGroup() }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshCorporateAccounts()
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
                await viewModel.loadCorporateAccounts()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            // Stats Cards
            HStack(spacing: AppSpacing.sm) {
                StatCard(
                    title: "Companies",
                    value: "\(viewModel.corporateAccountsCount)",
                    icon: "building.2.fill",
                    color: .appPrimary
                )
                
                StatCard(
                    title: "Total Employees",
                    value: "\(viewModel.totalEmployeesCount)",
                    icon: "person.2.fill",
                    color: .appSecondary
                )
            }
            
            // Quick Actions
            HStack(spacing: AppSpacing.sm) {
                QuickActionButton(
                    title: "Join Company",
                    icon: "building.2.badge.plus",
                    action: { router.navigateToJoinGroup() }
                )
                
                QuickActionButton(
                    title: "Create Company",
                    icon: "building.2",
                    action: { router.navigateToJoinGroup() }
                )
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }
    
    // MARK: - Corporate List
    private var corporateList: some View {
        List {
            // My Companies Section
            if !viewModel.myCompanies.isEmpty {
                Section("My Companies") {
                    ForEach(viewModel.myCompanies) { corporate in
                        CorporateRowView(corporate: corporate) {
                            router.navigate(to: .corporateDetail(corporate.id))
                        }
                    }
                }
            }
            
            // Employee Companies Section
            if !viewModel.employeeCompanies.isEmpty {
                Section("Employee") {
                    ForEach(viewModel.employeeCompanies) { corporate in
                        CorporateRowView(corporate: corporate) {
                            router.navigate(to: .corporateDetail(corporate.id))
                        }
                    }
                }
            }
            
            // Invited Companies Section
            if !viewModel.invitedCompanies.isEmpty {
                Section("Invitations") {
                    ForEach(viewModel.invitedCompanies) { corporate in
                        CorporateInvitationRowView(corporate: corporate) { accepted in
                            Task {
                                if accepted {
                                    await viewModel.acceptCorporateInvitation(corporate.id)
                                } else {
                                    await viewModel.declineCorporateInvitation(corporate.id)
                                }
                            }
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
            
            Text("Loading corporate accounts...")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.appTextSecondary)
            
            Text("No Corporate Accounts")
                .font(.appTitle)
                .foregroundColor(.appTextPrimary)
            
            Text("Join or create a corporate account to participate in company-wide challenges and wellness programs.")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            VStack(spacing: AppSpacing.md) {
                Button(action: { router.navigateToJoinGroup() }) {
                    Text("Join a Company")
                        .font(.appLabel)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.appPrimary)
                        .cornerRadius(AppSpacing.sm)
                }
                
                Button(action: { router.navigateToJoinGroup() }) {
                    Text("Create a Company")
                        .font(.appLabel)
                        .fontWeight(.semibold)
                        .foregroundColor(.appPrimary)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.appPrimary.opacity(0.1))
                        .cornerRadius(AppSpacing.sm)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppSpacing.md)
    }
    
    // MARK: - Sheet Views
    @ViewBuilder
    private func sheetView(for sheet: CorporateSheetDestination) -> some View {
        switch sheet {
        case .createCorporate:
            CreateCorporateView()
        case .editCorporate(let corporateId):
            if let corporate = viewModel.corporateAccounts.first(where: { $0.id == corporateId }) {
                EditCorporateView(corporate: corporate)
            }
        case .joinCorporate:
            JoinCorporateView()
        case .corporateInvite(let corporateId):
            if let corporate = viewModel.corporateAccounts.first(where: { $0.id == corporateId }) {
                CorporateInviteView(corporate: corporate)
            }
        case .corporateSettings(let corporateId):
            if let corporate = viewModel.corporateAccounts.first(where: { $0.id == corporateId }) {
                CorporateSettingsView(corporate: corporate)
            }
        }
    }
    
    // MARK: - Alert Views
    @ViewBuilder
    private func alertView(for alert: CorporateAlertDestination) -> some View {
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
        case .corporateInvitation(let title, let message):
            Alert(
                title: Text(title),
                message: message.map { Text($0) },
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Corporate Row View
struct CorporateRowView: View {
    let corporate: CorporateAccount
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Company Logo
                companyLogo
                
                // Company Details
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(corporate.companyName)
                        .font(.appLabel)
                        .fontWeight(.semibold)
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(1)
                    
                    Text(corporate.description)
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                    
                    HStack(spacing: AppSpacing.sm) {
                        // Industry Badge
                        IndustryBadge(industry: corporate.industry)
                        
                        // Employee Count
                        EmployeeCountBadge(count: corporate.employeeCount)
                        
                        // Size Badge
                        if let size = corporate.size {
                            CompanySizeBadge(size: size)
                        }
                    }
                }
                
                Spacer()
                
                // Role Indicator
                roleIndicator
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var companyLogo: some View {
        ZStack {
            Circle()
                .fill(corporate.industry.color.opacity(0.1))
                .frame(width: 50, height: 50)
            
            if let logoURL = corporate.logoURL {
                AsyncImage(url: logoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "building.2.fill")
                        .font(.title2)
                        .foregroundColor(corporate.industry.color)
                }
            } else {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(corporate.industry.color)
            }
        }
    }
    
    private var roleIndicator: some View {
        let isAdmin = corporate.adminIds.contains("current_user_id") // TODO: Get actual current user ID
        return Circle()
            .fill(isAdmin ? .appWarning : .appPrimary)
            .frame(width: 12, height: 12)
    }
}

// MARK: - Corporate Invitation Row View
struct CorporateInvitationRowView: View {
    let corporate: CorporateAccount
    let onResponse: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Company Logo
            companyLogo
            
            // Company Details
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(corporate.companyName)
                    .font(.appLabel)
                    .fontWeight(.semibold)
                    .foregroundColor(.appTextPrimary)
                
                Text("Invited by \(corporate.adminIds.first ?? "Admin")")
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                
                HStack(spacing: AppSpacing.sm) {
                    IndustryBadge(industry: corporate.industry)
                    EmployeeCountBadge(count: corporate.employeeCount)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: AppSpacing.xs) {
                Button(action: { onResponse(true) }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.appSuccess)
                }
                
                Button(action: { onResponse(false) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.appError)
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
    
    private var companyLogo: some View {
        ZStack {
            Circle()
                .fill(corporate.industry.color.opacity(0.1))
                .frame(width: 50, height: 50)
            
            Image(systemName: "building.2.fill")
                .font(.title2)
                .foregroundColor(corporate.industry.color)
        }
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

// MARK: - Industry Badge
struct IndustryBadge: View {
    let industry: Industry
    
    var body: some View {
        Text(industry.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(industry.color)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background(industry.color.opacity(0.1))
            .cornerRadius(AppSpacing.xxs)
    }
}

// MARK: - Employee Count Badge
struct EmployeeCountBadge: View {
    let count: Int?
    
    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: "person.2.fill")
                .font(.caption2)
            
            Text("\(count ?? 0)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.appTextSecondary)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
        .background(Color.appTextSecondary.opacity(0.1))
        .cornerRadius(AppSpacing.xxs)
    }
}

// MARK: - Company Size Badge
struct CompanySizeBadge: View {
    let size: CompanySize
    
    var body: some View {
        Text(size.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.appInfo)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background(Color.appInfo.opacity(0.1))
            .cornerRadius(AppSpacing.xxs)
    }
}

// MARK: - Extensions
extension Industry {
    var color: Color {
        switch self {
        case .technology: return .appPrimary
        case .healthcare: return .appSuccess
        case .finance: return .appSecondary
        case .education: return .appInfo
        case .retail: return .appWarning
        case .manufacturing: return .appTextSecondary
        case .consulting: return .appPrimary
        case .media: return .appSecondary
        case .nonprofit: return .appSuccess
        case .other: return .appTextSecondary
        }
    }
    
    var displayName: String {
        switch self {
        case .technology: return "Tech"
        case .healthcare: return "Healthcare"
        case .finance: return "Finance"
        case .education: return "Education"
        case .retail: return "Retail"
        case .manufacturing: return "Manufacturing"
        case .consulting: return "Consulting"
        case .media: return "Media"
        case .nonprofit: return "Nonprofit"
        case .other: return "Other"
        }
    }
}

extension CompanySize {
    var displayName: String {
        switch self {
        case .startup: return "Startup"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .enterprise: return "Enterprise"
        }
    }
}

// MARK: - Preview
struct CorporateView_Previews: PreviewProvider {
    static var previews: some View {
        CorporateView()
            .environment(\.router, AppRouter())
    }
}
