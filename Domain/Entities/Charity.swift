import Foundation

// MARK: - Charity Entity
struct Charity: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let category: CharityCategory
    let website: String?
    let logoUrl: String?
    let taxId: String?
    let isVerified: Bool
    let isActive: Bool
    let defaultPercentage: Decimal
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        category: CharityCategory,
        website: String? = nil,
        logoUrl: String? = nil,
        taxId: String? = nil,
        isVerified: Bool = false,
        isActive: Bool = true,
        defaultPercentage: Decimal = 50.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.website = website
        self.logoUrl = logoUrl
        self.taxId = taxId
        self.isVerified = isVerified
        self.isActive = isActive
        self.defaultPercentage = defaultPercentage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Charity Category
enum CharityCategory: String, CaseIterable, Codable {
    case education = "education"
    case healthcare = "healthcare"
    case environment = "environment"
    case poverty = "poverty"
    case animalWelfare = "animal_welfare"
    case disasterRelief = "disaster_relief"
    case arts = "arts"
    case sports = "sports"
    case technology = "technology"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .education: return "Education"
        case .healthcare: return "Healthcare"
        case .environment: return "Environment"
        case .poverty: return "Poverty Relief"
        case .animalWelfare: return "Animal Welfare"
        case .disasterRelief: return "Disaster Relief"
        case .arts: return "Arts & Culture"
        case .sports: return "Sports & Recreation"
        case .technology: return "Technology"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .education: return "book"
        case .healthcare: return "cross"
        case .environment: return "leaf"
        case .poverty: return "heart"
        case .animalWelfare: return "pawprint"
        case .disasterRelief: return "shield"
        case .arts: return "paintbrush"
        case .sports: return "sportscourt"
        case .technology: return "laptopcomputer"
        case .other: return "ellipsis"
        }
    }
}

// MARK: - Donation Record
struct DonationRecord: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let charityId: String
    let charityName: String
    let amount: Decimal
    let currency: String
    let goalId: String?
    let goalTitle: String?
    let paymentId: String
    let donationDate: Date
    let isTaxDeductible: Bool
    let receiptUrl: String?
    let metadata: [String: String]
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        charityId: String,
        charityName: String,
        amount: Decimal,
        currency: String = "USD",
        goalId: String? = nil,
        goalTitle: String? = nil,
        paymentId: String,
        donationDate: Date = Date(),
        isTaxDeductible: Bool = false,
        receiptUrl: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.userId = userId
        self.charityId = charityId
        self.charityName = charityName
        self.amount = amount
        self.currency = currency
        self.goalId = goalId
        self.goalTitle = goalTitle
        self.paymentId = paymentId
        self.donationDate = donationDate
        self.isTaxDeductible = isTaxDeductible
        self.receiptUrl = receiptUrl
        self.metadata = metadata
    }
}

// MARK: - Charity Selection
struct CharitySelection: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let goalId: String
    let charityId: String
    let charityName: String
    let percentage: Decimal
    let isDefault: Bool
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        goalId: String,
        charityId: String,
        charityName: String,
        percentage: Decimal = 50.0,
        isDefault: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.goalId = goalId
        self.charityId = charityId
        self.charityName = charityName
        self.percentage = percentage
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}
