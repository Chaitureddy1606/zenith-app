//
//  FinanceModels.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import Foundation
import SwiftUI
import MapKit

// MARK: - Core Finance Models

/// Represents a financial transaction with comprehensive details
struct Transaction: Identifiable, Codable {
    let id = UUID()
    var amount: Decimal
    var type: TransactionType
    var category: TransactionCategory
    var merchant: String
    var date: Date
    var account: Account
    var notes: String?
    var receiptImageData: Data?
    var location: Location?
    var priority: Priority
    var isRecurring: Bool
    var recurringInterval: RecurringInterval?
    var tags: Set<String>
    var currency: Currency
    var ocrData: OCRData?
    var isAnomaly: Bool
    var sharedWith: [String]?
    
    /// Computed property for display amount (positive for income, negative for expense)
    var displayAmount: Decimal {
        switch type {
        case .income:
            return amount
        case .expense:
            return -amount
        }
    }
    
    /// Computed property for amount color
    var amountColor: Color {
        switch type {
        case .income:
            return .green
        case .expense:
            return .red
        }
    }
    
    /// Computed property for formatted amount string with currency
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        
        let number = NSDecimalNumber(decimal: displayAmount)
        return formatter.string(from: number) ?? "\(currency.symbol)0.00"
    }
    
    /// Computed property for formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Computed property for relative date string
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// Transaction type enumeration
enum TransactionType: String, CaseIterable, Codable {
    case income = "income"
    case expense = "expense"
    
    var displayName: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        }
    }
    
    var iconName: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
}

/// Transaction category with icon and color
struct TransactionCategory: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var iconName: String
    var color: Color
    var budget: Decimal?
    
    /// Predefined categories following common financial tracking patterns
    static let predefinedCategories: [TransactionCategory] = [
        TransactionCategory(name: "Food & Dining", iconName: "fork.knife", color: .orange),
        TransactionCategory(name: "Transportation", iconName: "car.fill", color: .blue),
        TransactionCategory(name: "Shopping", iconName: "bag.fill", color: .purple),
        TransactionCategory(name: "Entertainment", iconName: "tv.fill", color: .pink),
        TransactionCategory(name: "Healthcare", iconName: "cross.fill", color: .red),
        TransactionCategory(name: "Utilities", iconName: "bolt.fill", color: .yellow),
        TransactionCategory(name: "Housing", iconName: "house.fill", color: .brown),
        TransactionCategory(name: "Education", iconName: "book.fill", color: .indigo),
        TransactionCategory(name: "Travel", iconName: "airplane", color: .cyan),
        TransactionCategory(name: "Gifts", iconName: "gift.fill", color: .mint),
        TransactionCategory(name: "Insurance", iconName: "shield.fill", color: .teal),
        TransactionCategory(name: "Investments", iconName: "chart.line.uptrend.xyaxis", color: .green),
        TransactionCategory(name: "Salary", iconName: "dollarsign.circle.fill", color: .green),
        TransactionCategory(name: "Freelance", iconName: "laptopcomputer", color: .blue),
        TransactionCategory(name: "Other", iconName: "ellipsis.circle.fill", color: .gray)
    ]
}

/// Financial account representation
struct Account: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var type: AccountType
    var balance: Decimal
    var currency: Currency
    var accountNumber: String?
    var routingNumber: String?
    var institution: String?
    var isShared: Bool
    var sharedWith: [String]? // User IDs or emails
    var permissions: [AccountPermission]
    var bankConnection: BankConnection?
    var lastSyncDate: Date?
    var isActive: Bool
    
    /// Computed property for formatted balance
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        return formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "\(currency.symbol)0.00"
    }
}

/// Account type enumeration
enum AccountType: String, CaseIterable, Codable {
    case checking = "checking"
    case savings = "savings"
    case creditCard = "creditCard"
    case investment = "investment"
    case cash = "cash"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .creditCard: return "Credit Card"
        case .investment: return "Investment"
        case .cash: return "Cash"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .checking: return "creditcard.fill"
        case .savings: return "banknote.fill"
        case .creditCard: return "creditcard"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .cash: return "dollarsign.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// Location information for transactions
struct Location: Codable {
    var coordinate: CLLocationCoordinate2D
    var name: String?
    var address: String?
    var city: String?
    var state: String?
    var country: String?
    var postalCode: String?
    
    /// Computed property for formatted address
    var formattedAddress: String {
        var components: [String] = []
        
        if let name = name, !name.isEmpty {
            components.append(name)
        }
        
        if let address = address, !address.isEmpty {
            components.append(address)
        }
        
        if let city = city, !city.isEmpty {
            components.append(city)
        }
        
        if let state = state, !state.isEmpty {
            components.append(state)
        }
        
        if let postalCode = postalCode, !postalCode.isEmpty {
            components.append(postalCode)
        }
        
        if let country = country, !country.isEmpty {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}

/// Priority levels for transactions
enum Priority: String, CaseIterable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .normal: return .green
        case .high: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .normal: return "circle"
        case .high: return "exclamationmark.triangle"
        }
    }
}

/// Recurring transaction intervals
enum RecurringInterval: String, CaseIterable, Codable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
}

/// Bill frequency options
enum BillFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Budget Models

/// Budget tracking for categories
struct Budget: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var category: TransactionCategory
    var amount: Decimal
    var currency: Currency
    var period: BudgetPeriod
    var startDate: Date
    var endDate: Date
    var spent: Decimal
    var isShared: Bool
    var sharedWith: [String]?
    var aiSuggestions: [BudgetSuggestion]
    var isActive: Bool
    
    /// Computed property for remaining budget
    var remaining: Decimal {
        amount - spent
    }
    
    /// Computed property for spending percentage
    var spendingPercentage: Decimal {
        guard amount > 0 else { return 0 }
        return spent / amount
    }
    
    /// Computed property for progress value (0.0 - 1.0)
    var progress: Double {
        Double(truncating: spendingPercentage as NSNumber)
    }
    
    /// Computed property for days remaining
    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }
    
    /// Computed property for progress color
    var progressColor: Color {
        let percentage = Double(truncating: spendingPercentage as NSNumber)
        switch percentage {
        case 0..<0.7:
            return .green
        case 0.7..<0.9:
            return .orange
        default:
            return .red
        }
    }
}

/// Budget period options
enum BudgetPeriod: String, Codable, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
    
    var iconName: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.plus"
        case .yearly: return "calendar.badge.exclamationmark"
        case .custom: return "calendar.badge.questionmark"
        }
    }
}

/// AI budget suggestion
struct BudgetSuggestion: Codable, Hashable {
    var id = UUID()
    var type: SuggestionType
    var title: String
    var description: String
    var recommendedAmount: Decimal?
    var confidence: Double
    var reasoning: String
    var isApplied: Bool
    var createdAt: Date
}

/// Budget suggestion types
enum SuggestionType: String, Codable, CaseIterable {
    case increase = "increase"
    case decrease = "decrease"
    case reallocate = "reallocate"
    case newCategory = "new_category"
    
    var displayName: String {
        switch self {
        case .increase: return "Increase Budget"
        case .decrease: return "Decrease Budget"
        case .reallocate: return "Reallocate Funds"
        case .newCategory: return "New Category"
        }
    }
    
    var iconName: String {
        switch self {
        case .increase: return "arrow.up.circle.fill"
        case .decrease: return "arrow.down.circle.fill"
        case .reallocate: return "arrow.triangle.2.circlepath"
        case .newCategory: return "plus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .increase: return .green
        case .decrease: return .red
        case .reallocate: return .blue
        case .newCategory: return .purple
        }
    }
}

// MARK: - Bill Models

/// Bill and subscription tracking
struct Bill: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var amount: Decimal
    var currency: Currency
    var dueDate: Date
    var isPaid: Bool
    var paidDate: Date?
    var category: TransactionCategory
    var account: Account
    var isRecurring: Bool
    var recurringInterval: RecurringInterval?
    var serviceProvider: String
    var accountNumber: String?
    var notes: String?
    var attachments: [Attachment]
    var priority: Priority
    var isShared: Bool
    var sharedWith: [String]?
    var aiPaymentSuggestion: PaymentSuggestion?
    var notifications: [BillNotification]
    
    /// Computed property for days until due
    var daysUntilDue: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day ?? 0
    }
    
    /// Computed property for status
    var status: BillStatus {
        if isPaid {
            return .paid
        } else if daysUntilDue < 0 {
            return .overdue
        } else if daysUntilDue <= 7 {
            return .dueSoon
        } else {
            return .upcoming
        }
    }
    
    /// Computed property for status color
    var statusColor: Color {
        switch status {
        case .paid: return .green
        case .overdue: return .red
        case .dueSoon: return .orange
        case .upcoming: return .blue
        }
    }
    
    /// Computed property for status text
    var statusText: String {
        if isPaid {
            return "Paid"
        } else if daysUntilDue < 0 {
            return "Overdue"
        } else if daysUntilDue == 0 {
            return "Due Today"
        } else if daysUntilDue == 1 {
            return "Due Tomorrow"
        } else {
            return "Due in \(daysUntilDue) days"
        }
    }
}

/// Bill status enumeration
enum BillStatus: String, Codable, CaseIterable {
    case paid = "paid"
    case overdue = "overdue"
    case dueSoon = "due_soon"
    case upcoming = "upcoming"
    
    var displayName: String {
        switch self {
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        case .dueSoon: return "Due Soon"
        case .upcoming: return "Upcoming"
        }
    }
    
    var iconName: String {
        switch self {
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .dueSoon: return "clock.fill"
        case .upcoming: return "calendar.badge.clock"
        }
    }
}

/// AI payment suggestion for bills
struct PaymentSuggestion: Codable, Hashable {
    var id = UUID()
    var suggestedDate: Date
    var reasoning: String
    var estimatedSavings: Decimal?
    var confidence: Double
    var isApplied: Bool
}

/// Bill notification settings
struct BillNotification: Codable, Hashable {
    var id = UUID()
    var type: NotificationType
    var daysBeforeDue: Int
    var isEnabled: Bool
    var message: String
}

/// Notification types for bills
enum NotificationType: String, Codable, CaseIterable {
    case reminder = "reminder"
    case dueToday = "due_today"
    case overdue = "overdue"
    case paymentConfirmation = "payment_confirmation"
    
    var displayName: String {
        switch self {
        case .reminder: return "Reminder"
        case .dueToday: return "Due Today"
        case .overdue: return "Overdue"
        case .paymentConfirmation: return "Payment Confirmation"
        }
    }
}

// MARK: - Savings Goals Models

/// Savings goal categories
enum SavingsGoalCategory: String, CaseIterable, Codable {
    case emergency = "emergency"
    case vacation = "vacation"
    case home = "home"
    case vehicle = "vehicle"
    case education = "education"
    case retirement = "retirement"
    case wedding = "wedding"
    case business = "business"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .emergency: return "Emergency Fund"
        case .vacation: return "Vacation"
        case .home: return "Home"
        case .vehicle: return "Vehicle"
        case .education: return "Education"
        case .retirement: return "Retirement"
        case .wedding: return "Wedding"
        case .business: return "Business"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .emergency: return "shield.fill"
        case .vacation: return "airplane"
        case .home: return "house.fill"
        case .vehicle: return "car.fill"
        case .education: return "book.fill"
        case .retirement: return "clock.fill"
        case .wedding: return "heart.fill"
        case .business: return "briefcase.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .emergency: return .red
        case .vacation: return .blue
        case .home: return .green
        case .vehicle: return .orange
        case .education: return .purple
        case .retirement: return .yellow
        case .wedding: return .pink
        case .business: return .gray
        case .other: return .mint
        }
    }
}

/// Savings goal tracking
struct SavingsGoal: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var targetAmount: Decimal
    var currentAmount: Decimal
    var currency: Currency
    var targetDate: Date?
    var monthlyContribution: Decimal
    var category: SavingsGoalCategory
    var notes: String?
    var isShared: Bool
    var sharedWith: [String]?
    var contributions: [Contribution]
    var aiForecast: GoalForecast?
    var isActive: Bool
    
    /// Computed property for progress percentage
    var progressPercentage: Decimal {
        guard targetAmount > 0 else { return 0 }
        return currentAmount / targetAmount
    }
    
    /// Computed property for remaining amount
    var remaining: Decimal {
        targetAmount - currentAmount
    }
    
    /// Computed property for estimated completion date
    var estimatedCompletionDate: Date? {
        guard monthlyContribution > 0 else { return nil }
        let remaining = self.remaining
        let monthsRemaining = remaining / monthlyContribution
        return Calendar.current.date(byAdding: .month, value: Int(truncating: monthsRemaining as NSNumber), to: Date())
    }
    
    /// Computed property for progress value (0.0 - 1.0)
    var progress: Double {
        Double(truncating: progressPercentage as NSNumber)
    }
}

/// AI forecast for savings goals
struct GoalForecast: Codable, Hashable {
    var id = UUID()
    var estimatedCompletionDate: Date
    var confidence: Double
    var factors: [String]
    var recommendations: [String]
    var lastUpdated: Date
}

/// Contribution to savings goals
struct Contribution: Codable, Hashable {
    let id = UUID()
    var amount: Decimal
    var date: Date
    var notes: String?
    var source: String
    var isRecurring: Bool
}

// MARK: - Finance Summary Models

/// Financial overview summary
struct FinanceSummary: Codable {
    var totalBalance: Decimal
    var netWorth: Decimal
    var monthlyIncome: Decimal
    var monthlyExpenses: Decimal
    var monthlySavings: Decimal
    var upcomingBillsCount: Int
    var overdueBillsCount: Int
    var recentTransactions: [Transaction]
    var categorySpending: [CategorySpending]
    var aiInsights: [FinancialInsight]
    var cashFlowForecast: CashFlowForecast?
    var netWorthForecast: NetWorthForecast?
    var lastUpdated: Date
}

/// Category spending summary
struct CategorySpending: Codable, Hashable {
    var category: TransactionCategory
    var amount: Decimal
    var percentage: Decimal
    var budget: Decimal?
    var remaining: Decimal?
    var isOverBudget: Bool
}





/// Enhanced financial insight with actionable recommendations
struct FinancialInsight: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var type: InsightType
    var category: String
    var amount: Decimal?
    var currency: Currency
    var date: Date
    var actionable: Bool
    var actionTitle: String?
    var actionURL: String?
    var confidence: Double
    var tags: Set<String>
    var isRead: Bool
    var priority: InsightPriority
    
    /// Computed property for icon name
    var iconName: String {
        type.iconName
    }
    
    /// Computed property for color
    var color: Color {
        type.color
    }
}

/// Enhanced insight types
enum InsightType: String, Codable, CaseIterable {
    case spending = "spending"
    case saving = "saving"
    case budget = "budget"
    case anomaly = "anomaly"
    case opportunity = "opportunity"
    case risk = "risk"
    case trend = "trend"
    case forecast = "forecast"
    
    var displayName: String {
        switch self {
        case .spending: return "Spending"
        case .saving: return "Saving"
        case .budget: return "Budget"
        case .anomaly: return "Anomaly"
        case .opportunity: return "Opportunity"
        case .risk: return "Risk"
        case .trend: return "Trend"
        case .forecast: return "Forecast"
        }
    }
    
    var iconName: String {
        switch self {
        case .spending: return "arrow.up.circle.fill"
        case .saving: return "arrow.down.circle.fill"
        case .budget: return "chart.pie.fill"
        case .anomaly: return "exclamationmark.triangle.fill"
        case .opportunity: return "lightbulb.fill"
        case .risk: return "exclamationmark.octagon.fill"
        case .trend: return "chart.line.uptrend.xyaxis"
        case .forecast: return "crystal.ball.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .spending: return .red
        case .saving: return .green
        case .budget: return .purple
        case .anomaly: return .orange
        case .opportunity: return .blue
        case .risk: return .red
        case .trend: return .indigo
        case .forecast: return .teal
        }
    }
}

/// Insight priority levels
enum InsightPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

/// Tax report model for year-end summaries
struct TaxReport: Identifiable, Codable, Hashable {
    let id = UUID()
    var year: Int
    var totalIncome: Decimal
    var totalExpenses: Decimal
    var deductibleExpenses: Decimal
    var netIncome: Decimal
    var currency: Currency
    var categories: [CategorySummary]
    var generatedDate: Date
    var isExported: Bool
    var exportFormat: ExportFormat?
    
    /// Computed property for effective tax rate estimate
    var estimatedTaxRate: Decimal {
        // Simplified tax rate calculation
        switch netIncome {
        case 0..<10000: return 0.10
        case 10000..<40000: return 0.15
        case 40000..<85000: return 0.25
        case 85000..<163000: return 0.28
        case 163000..<200000: return 0.33
        case 200000..<500000: return 0.35
        default: return 0.37
        }
    }
    
    /// Computed property for estimated taxes
    var estimatedTaxes: Decimal {
        netIncome * estimatedTaxRate
    }
}

/// Category summary for tax reports
struct CategorySummary: Codable, Hashable {
    var category: String
    var totalAmount: Decimal
    var transactionCount: Int
    var isDeductible: Bool
}

/// Export format options
enum ExportFormat: String, Codable, CaseIterable {
    case csv = "csv"
    case pdf = "pdf"
    case json = "json"
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .pdf: return "PDF"
        case .json: return "JSON"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .pdf: return "pdf"
        case .json: return "json"
        }
    }
    
    var iconName: String {
        switch self {
        case .csv: return "tablecells"
        case .pdf: return "doc.text"
        case .json: return "curlybraces"
        }
    }
    
    var color: Color {
        switch self {
        case .csv: return .blue
        case .pdf: return .red
        case .json: return .green
        }
    }
}



/// Recurring transaction model
struct RecurringTransaction: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var amount: Decimal
    var type: TransactionType
    var category: TransactionCategory
    var account: Account
    var currency: Currency
    var interval: RecurringInterval
    var startDate: Date
    var endDate: Date?
    var nextRunDate: Date
    var isActive: Bool
    var lastRunDate: Date?
    var totalRuns: Int
    var maxRuns: Int?
    var notes: String?
    
    /// Computed property for next run date
    var formattedNextRun: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: nextRunDate)
    }
}



/// Shared account invitation model
struct SharedAccountInvitation: Identifiable, Codable, Hashable {
    let id = UUID()
    var accountId: String
    var invitedEmail: String
    var invitedBy: String
    var permissions: [PermissionType]
    var status: InvitationStatus
    var sentDate: Date
    var expiresDate: Date
    var message: String?
    
    /// Computed property for days until expiration
    var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiresDate)
        return max(0, components.day ?? 0)
    }
}

/// Invitation status
enum InvitationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .expired: return "Expired"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .expired: return .gray
        }
    }
}

/// Attachment types for finance
enum FinanceAttachmentType: String, Codable, CaseIterable {
    case image = "image"
    case pdf = "pdf"
    case document = "document"
    case receipt = "receipt"
    
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .pdf: return "PDF"
        case .document: return "Document"
        case .receipt: return "Receipt"
        }
    }
    
    var iconName: String {
        switch self {
        case .image: return "photo"
        case .pdf: return "doc.text"
        case .document: return "doc"
        case .receipt: return "receipt"
        }
    }
}

/// Attachment model for receipts and documents
struct Attachment: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var type: FinanceAttachmentType
    var data: Data
    var size: Int
    var uploadedDate: Date
    var tags: Set<String>
    var isOCRProcessed: Bool
    var ocrData: OCRData?
}



/// Cash flow forecast for AI predictions
struct CashFlowForecast: Codable, Hashable {
    var id = UUID()
    var period: ForecastPeriod
    var predictedIncome: Decimal
    var predictedExpenses: Decimal
    var predictedSavings: Decimal
    var confidence: Double
    var factors: [String]
    var lastUpdated: Date
}

/// Net worth forecast for AI predictions
struct NetWorthForecast: Codable, Hashable {
    var id = UUID()
    var targetDate: Date
    var predictedNetWorth: Decimal
    var confidence: Double
    var growthRate: Decimal
    var factors: [String]
    var lastUpdated: Date
}

/// Forecast period options
enum ForecastPeriod: String, Codable, CaseIterable {
    case oneMonth = "1_month"
    case threeMonths = "3_months"
    case sixMonths = "6_months"
    case oneYear = "1_year"
    case fiveYears = "5_years"
    
    var displayName: String {
        switch self {
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        case .fiveYears: return "5 Years"
        }
    }
}

/// Currency model for multi-currency support
struct Currency: Identifiable, Codable, Hashable {
    let id = UUID()
    var code: String // ISO 4217 code (USD, EUR, etc.)
    var symbol: String // $, €, etc.
    var name: String // US Dollar, Euro, etc.
    var exchangeRate: Decimal // Rate relative to base currency
    
    static let usd = Currency(code: "USD", symbol: "$", name: "US Dollar", exchangeRate: 1.0)
    static let eur = Currency(code: "EUR", symbol: "€", name: "Euro", exchangeRate: 1.1)
    static let gbp = Currency(code: "GBP", symbol: "£", name: "British Pound", exchangeRate: 1.3)
    static let jpy = Currency(code: "JPY", symbol: "¥", name: "Japanese Yen", exchangeRate: 0.007)
    
    static let all: [Currency] = [.usd, .eur, .gbp, .jpy]
}

/// OCR data for receipt scanning and auto-fill
struct OCRData: Codable, Hashable {
    var merchantName: String?
    var amount: Decimal?
    var date: Date?
    var category: String?
    var confidence: Double // OCR confidence score (0.0 - 1.0)
    var rawText: String // Raw OCR text for debugging
}

/// Enhanced account model with bank sync support
struct BankConnection: Codable, Hashable, Identifiable {
    var id: String { "\(institutionId)_\(accountId)" }
    var institutionId: String
    var accountId: String
    var connectionStatus: ConnectionStatus
    var lastSyncDate: Date?
    var errorMessage: String?
    var requiresReauthorization: Bool
}

/// Bank connection status
enum ConnectionStatus: String, Codable, CaseIterable {
    case connected = "connected"
    case connecting = "connecting"
    case disconnected = "disconnected"
    case error = "error"
    case requiresAuth = "requires_auth"
    
    var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        case .requiresAuth: return "Reauthorization Required"
        }
    }
    
    var iconName: String {
        switch self {
        case .connected: return "checkmark.circle.fill"
        case .connecting: return "arrow.clockwise.circle"
        case .disconnected: return "xmark.circle"
        case .error: return "exclamationmark.triangle.fill"
        case .requiresAuth: return "lock.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .connecting: return .blue
        case .disconnected: return .gray
        case .error: return .red
        case .requiresAuth: return .orange
        }
    }
}

/// Account permissions for shared accounts
struct AccountPermission: Codable, Hashable {
    var userId: String
    var permissions: [PermissionType]
    var grantedDate: Date
    var grantedBy: String
}

/// Permission types for shared accounts
enum PermissionType: String, Codable, CaseIterable {
    case view = "view"
    case edit = "edit"
    case delete = "delete"
    case share = "share"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .view: return "View Only"
        case .edit: return "Can Edit"
        case .delete: return "Can Delete"
        case .share: return "Can Share"
        case .admin: return "Administrator"
        }
    }
}

// MARK: - Extensions

extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

 