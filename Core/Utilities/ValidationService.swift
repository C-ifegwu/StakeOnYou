import Foundation

// MARK: - Validation Service Implementation
class ValidationServiceImpl: ValidationService {
    
    // MARK: - Email Validation
    func validateEmail(_ email: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            throw ValidationError.emptyEmail
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: trimmedEmail) else {
            throw ValidationError.invalidEmail
        }
        
        guard trimmedEmail.count <= 254 else {
            throw ValidationError.emailTooLong
        }
    }
    
    // MARK: - Password Validation
    func validatePassword(_ password: String) throws {
        guard !password.isEmpty else {
            throw ValidationError.emptyPassword
        }
        
        guard password.count >= 8 else {
            throw ValidationError.passwordTooShort
        }
        
        guard password.count <= 128 else {
            throw ValidationError.passwordTooLong
        }
        
        // Check for at least one uppercase letter
        let uppercaseRegex = ".*[A-Z].*"
        let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
        guard uppercasePredicate.evaluate(with: password) else {
            throw ValidationError.passwordMissingUppercase
        }
        
        // Check for at least one number
        let numberRegex = ".*[0-9].*"
        let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        guard numberPredicate.evaluate(with: password) else {
            throw ValidationError.passwordMissingNumber
        }
        
        // Optional: Check for special characters (recommended but not required)
        let specialCharRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?].*"
        let specialCharPredicate = NSPredicate(format: "SELF MATCHES %@", specialCharRegex)
        if specialCharPredicate.evaluate(with: password) {
            // Password has special characters - this is good
        }
    }
    
    // MARK: - Full Name Validation
    func validateFullName(_ fullName: String) throws {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyFullName
        }
        
        guard trimmedName.count >= 2 else {
            throw ValidationError.fullNameTooShort
        }
        
        guard trimmedName.count <= 100 else {
            throw ValidationError.fullNameTooLong
        }
        
        // Check if name contains only letters, spaces, hyphens, and apostrophes
        let nameRegex = "^[a-zA-Z\\s\\-']+$"
        let namePredicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)
        
        guard namePredicate.evaluate(with: trimmedName) else {
            throw ValidationError.invalidFullName
        }
        
        // Check if name has at least two parts (first and last name)
        let nameParts = trimmedName.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        guard nameParts.count >= 2 else {
            throw ValidationError.fullNameIncomplete
        }
    }
    
    // MARK: - Referral Code Validation
    func validateReferralCode(_ code: String?) throws {
        // Referral code is optional, so if it's nil, it's valid
        guard let code = code else { return }
        
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If provided, it should not be empty
        guard !trimmedCode.isEmpty else {
            throw ValidationError.emptyReferralCode
        }
        
        // Referral codes are typically alphanumeric and 6-12 characters
        let codeRegex = "^[A-Z0-9]{6,12}$"
        let codePredicate = NSPredicate(format: "SELF MATCHES %@", codeRegex)
        
        guard codePredicate.evaluate(with: trimmedCode) else {
            throw ValidationError.invalidReferralCode
        }
    }
    
    // MARK: - Password Strength Calculation
    func calculatePasswordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        // Length
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }
        
        // Character variety
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]", options: .regularExpression) != nil { score += 1 }
        
        // Deduct points for common patterns
        if password.lowercased() == password { score -= 1 } // All lowercase
        if password.uppercased() == password { score -= 1 } // All uppercase
        if password.range(of: "123", options: .regularExpression) != nil { score -= 1 } // Sequential numbers
        if password.range(of: "abc", options: .regularExpression) != nil { score -= 1 } // Sequential letters
        
        switch score {
        case 0...2:
            return .weak
        case 3...4:
            return .fair
        case 5...6:
            return .good
        case 7...8:
            return .strong
        default:
            return .veryStrong
        }
    }
}

// MARK: - Validation Errors
enum ValidationError: LocalizedError, Equatable {
    case emptyEmail
    case invalidEmail
    case emailTooLong
    case emptyPassword
    case passwordTooShort
    case passwordTooLong
    case passwordMissingUppercase
    case passwordMissingNumber
    case emptyFullName
    case fullNameTooShort
    case fullNameTooLong
    case invalidFullName
    case fullNameIncomplete
    case emptyReferralCode
    case invalidReferralCode
    
    var errorDescription: String? {
        switch self {
        case .emptyEmail:
            return "Email address is required"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .emailTooLong:
            return "Email address is too long"
        case .emptyPassword:
            return "Password is required"
        case .passwordTooShort:
            return "Password must be at least 8 characters long"
        case .passwordTooLong:
            return "Password is too long"
        case .passwordMissingUppercase:
            return "Password must contain at least one uppercase letter"
        case .passwordMissingNumber:
            return "Password must contain at least one number"
        case .emptyFullName:
            return "Full name is required"
        case .fullNameTooShort:
            return "Full name must be at least 2 characters long"
        case .fullNameTooLong:
            return "Full name is too long"
        case .invalidFullName:
            return "Full name can only contain letters, spaces, hyphens, and apostrophes"
        case .fullNameIncomplete:
            return "Please enter your first and last name"
        case .emptyReferralCode:
            return "Referral code cannot be empty"
        case .invalidReferralCode:
            return "Referral code must be 6-12 alphanumeric characters"
        }
    }
}

// MARK: - Password Strength
enum PasswordStrength: String, CaseIterable {
    case weak = "weak"
    case fair = "fair"
    case good = "good"
    case strong = "strong"
    case veryStrong = "veryStrong"
    
    var displayName: String {
        switch self {
        case .weak:
            return "Weak"
        case .fair:
            return "Fair"
        case .good:
            return "Good"
        case .strong:
            return "Strong"
        case .veryStrong:
            return "Very Strong"
        }
    }
    
    var color: String {
        switch self {
        case .weak:
            return "red"
        case .fair:
            return "orange"
        case .good:
            return "yellow"
        case .strong:
            return "green"
        case .veryStrong:
            return "blue"
        }
    }
    
    var iconName: String {
        switch self {
        case .weak:
            return "exclamationmark.triangle"
        case .fair:
            return "minus.circle"
        case .good:
            return "checkmark.circle"
        case .strong:
            return "checkmark.circle.fill"
        case .veryStrong:
            return "shield.checkmark.fill"
        }
    }
}
