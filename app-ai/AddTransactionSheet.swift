//
//  AddTransactionSheet.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import SwiftUI
import PhotosUI
import MapKit

/// Comprehensive transaction form sheet for adding and editing financial transactions
/// Implements AI-powered categorization and comprehensive data collection
struct AddTransactionSheet: View {
    // MARK: - Properties
    
    /// Finance manager for data operations
    let financeManager: FinanceManager
    
    /// Transaction being edited (nil for new transactions)
    let transaction: Transaction?
    
    /// Sheet presentation mode
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Form State
    
    /// Transaction amount
    @State private var amount: String = ""
    
    /// Transaction type (income/expense)
    @State private var transactionType: TransactionType = .expense
    
    /// Selected category
    @State private var selectedCategory: TransactionCategory?
    
    /// Merchant name
    @State private var merchant: String = ""
    
    /// Transaction date
    @State private var date = Date()
    
    /// Selected account
    @State private var selectedAccount: Account?
    
    /// Transaction notes
    @State private var notes: String = ""
    
    /// Priority level
    @State private var priority: Priority = .normal
    
    /// Recurring transaction flag
    @State private var isRecurring = false
    
    /// Recurring interval
    @State private var recurringInterval: RecurringInterval = .monthly
    
    /// Receipt image
    @State private var receiptImage: UIImage?
    
    /// Location data
    @State private var location: Location?
    
    /// Tags
    @State private var tags: Set<String> = []
    
    /// New tag input
    @State private var newTag: String = ""
    
    // MARK: - UI State
    
    /// Shows category picker
    @State private var showingCategoryPicker = false
    
    /// Shows account picker
    @State private var showingAccountPicker = false
    
    /// Shows location picker
    @State private var showingLocationPicker = false
    
    /// Shows photo picker
    @State private var showingPhotoPicker = false
    
    /// Shows camera
    @State private var showingCamera = false
    
    /// Shows tag input
    @State private var showingTagInput = false
    
    /// AI categorization in progress
    @State private var isAICategorizing = false
    
    /// Form validation errors
    @State private var validationErrors: Set<ValidationError> = []
    
    // MARK: - Initialization
    
    init(financeManager: FinanceManager, transaction: Transaction? = nil) {
        self.financeManager = financeManager
        self.transaction = transaction
        
        // Initialize form with transaction data if editing
        if let transaction = transaction {
            _amount = State(initialValue: String(describing: transaction.amount))
            _transactionType = State(initialValue: transaction.type)
            _selectedCategory = State(initialValue: transaction.category)
            _merchant = State(initialValue: transaction.merchant)
            _date = State(initialValue: transaction.date)
            _selectedAccount = State(initialValue: transaction.account)
            _notes = State(initialValue: transaction.notes ?? "")
            _priority = State(initialValue: transaction.priority)
            _isRecurring = State(initialValue: transaction.isRecurring)
            _recurringInterval = State(initialValue: transaction.recurringInterval ?? .monthly)
            _tags = State(initialValue: transaction.tags)
            _location = State(initialValue: transaction.location)
        }
    }
    
    // MARK: - Main View Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                basicInformationSection
                
                // Category & Account Section
                categoryAccountSection
                
                // Additional Details Section
                additionalDetailsSection
                
                // Attachments Section
                attachmentsSection
                
                // AI Features Section
                aiFeaturesSection
            }
            .navigationTitle(transaction == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerSheet(selectedCategory: $selectedCategory)
            }
            .sheet(isPresented: $showingAccountPicker) {
                AccountPickerSheet(selectedAccount: $selectedAccount)
            }
            .sheet(isPresented: $showingLocationPicker) {
                FinanceLocationPickerSheet(location: $location)
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(image: $receiptImage)
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $receiptImage)
            }
            .alert("Add Tag", isPresented: $showingTagInput) {
                TextField("Tag name", text: $newTag)
                Button("Add") {
                    addTag()
                }
                Button("Cancel", role: .cancel) { }
            }
            .onAppear {
                setupDefaultValues()
            }
        }
    }
    
    // MARK: - Basic Information Section
    
    /// Basic transaction information fields
    private var basicInformationSection: some View {
        Section("Basic Information") {
            // Amount Field
            HStack {
                Text("Amount")
                    .foregroundColor(.primary)
                
                Spacer()
                
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(transactionType == .income ? .green : .red)
            }
            .accessibilityLabel("Transaction amount")
            .accessibilityHint("Enter the transaction amount")
            
            // Transaction Type Picker
            Picker("Type", selection: $transactionType) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.iconName)
                            .foregroundColor(type == .income ? .green : .red)
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Transaction type")
            .accessibilityHint("Select income or expense")
            
            // Merchant Field
            HStack {
                Text("Merchant")
                    .foregroundColor(.primary)
                
                TextField("Merchant name", text: $merchant)
                    .textFieldStyle(.roundedBorder)
            }
            .accessibilityLabel("Merchant name")
            .accessibilityHint("Enter the merchant or business name")
            
            // Date Picker
            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .accessibilityLabel("Transaction date")
                .accessibilityHint("Select the date and time of the transaction")
        }
    }
    
    // MARK: - Category & Account Section
    
    /// Category and account selection
    private var categoryAccountSection: some View {
        Section("Category & Account") {
            // Category Selection
            HStack {
                Text("Category")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    showingCategoryPicker = true
                } label: {
                    HStack {
                        if let category = selectedCategory {
                            Image(systemName: category.iconName)
                                .foregroundColor(category.color)
                            Text(category.name)
                                .foregroundColor(.primary)
                        } else {
                            Text("Select Category")
                                .foregroundColor(.secondary)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .accessibilityLabel("Transaction category")
            .accessibilityHint("Tap to select a category")
            
            // Account Selection
            HStack {
                Text("Account")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    showingAccountPicker = true
                } label: {
                    HStack {
                        if let account = selectedAccount {
                            Image(systemName: account.type.iconName)
                                .foregroundColor(.accentColor)
                            Text(account.name)
                                .foregroundColor(.primary)
                        } else {
                            Text("Select Account")
                                .foregroundColor(.secondary)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .accessibilityLabel("Account")
            .accessibilityHint("Tap to select an account")
        }
    }
    
    // MARK: - Additional Details Section
    
    /// Additional transaction details
    private var additionalDetailsSection: some View {
        Section("Additional Details") {
            // Notes Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .foregroundColor(.primary)
                
                TextField("Add notes...", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
            .accessibilityLabel("Transaction notes")
            .accessibilityHint("Add optional notes about the transaction")
            
            // Priority Selection
            Picker("Priority", selection: $priority) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    HStack {
                        Circle()
                            .fill(priority.color)
                            .frame(width: 12, height: 12)
                        Text(priority.displayName)
                    }
                    .tag(priority)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Transaction priority")
            .accessibilityHint("Select the priority level")
            
            // Recurring Transaction
            Toggle("Recurring Transaction", isOn: $isRecurring)
                .accessibilityLabel("Recurring transaction")
                .accessibilityHint("Toggle if this transaction repeats")
            
            if isRecurring {
                Picker("Frequency", selection: $recurringInterval) {
                    ForEach(RecurringInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Recurring frequency")
                .accessibilityHint("Select how often this transaction repeats")
            }
            
            // Tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .foregroundColor(.primary)
                
                if !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(tags), id: \.self) { tag in
                                TagView(tag: tag) {
                                    tags.remove(tag)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                Button("Add Tag") {
                    showingTagInput = true
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            .accessibilityLabel("Transaction tags")
            .accessibilityHint("Add tags to organize transactions")
        }
    }
    
    // MARK: - Attachments Section
    
    /// Receipt and location attachments
    private var attachmentsSection: some View {
        Section("Attachments") {
            // Receipt Photo
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Receipt Photo")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let receiptImage = receiptImage {
                        Button("Remove") {
                            self.receiptImage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                
                if let receiptImage = receiptImage {
                    Image(uiImage: receiptImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                HStack(spacing: 12) {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .accessibilityLabel("Receipt photo")
            .accessibilityHint("Add a photo of the receipt")
            
            // Location
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Location")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if location != nil {
                        Button("Remove") {
                            location = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                
                if let location = location {
                    LocationPreviewView(location: location)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    showingLocationPicker = true
                } label: {
                    Label(location == nil ? "Add Location" : "Change Location", 
                          systemImage: "location")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .accessibilityLabel("Transaction location")
            .accessibilityHint("Add location information")
        }
    }
    
    // MARK: - AI Features Section
    
    /// AI-powered features
    private var aiFeaturesSection: some View {
        Section("AI Features") {
            // Auto-categorization
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("AI Categorization")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isAICategorizing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                Text("Automatically categorize this transaction based on merchant and amount patterns")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    performAICategorization()
                } label: {
                    Label("Categorize Automatically", systemImage: "brain.head.profile")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(merchant.isEmpty || amount.isEmpty || isAICategorizing)
            }
            .accessibilityLabel("AI categorization")
            .accessibilityHint("Use AI to automatically categorize the transaction")
        }
    }
    
    // MARK: - Toolbar Buttons
    
    /// Cancel button
    private var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
        .accessibilityLabel("Cancel")
        .accessibilityHint("Cancel adding transaction")
    }
    
    /// Save button
    private var saveButton: some View {
        Button("Save") {
            saveTransaction()
        }
        .fontWeight(.semibold)
        .disabled(!isFormValid)
        .accessibilityLabel("Save transaction")
        .accessibilityHint("Save the transaction to your finance records")
    }
    
    // MARK: - Helper Methods
    
    /// Sets up default values for the form
    private func setupDefaultValues() {
        if selectedCategory == nil {
            selectedCategory = TransactionCategory.predefinedCategories.first
        }
        
        if selectedAccount == nil {
            selectedAccount = financeManager.accounts.first
        }
    }
    
    /// Adds a new tag
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.insert(trimmedTag)
            newTag = ""
        }
    }
    
    /// Performs AI categorization
    private func performAICategorization() {
        guard !merchant.isEmpty, let amountValue = Decimal(string: amount) else { return }
        
        isAICategorizing = true
        
        // Simulate AI processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simple AI logic based on merchant keywords and amount
            let suggestedCategory = suggestCategory(for: merchant, amount: amountValue)
            selectedCategory = suggestedCategory
            isAICategorizing = false
            
            // Provide haptic feedback
            HapticManager.shared.success()
        }
    }
    
    /// Suggests a category based on merchant and amount
    /// - Parameters:
    ///   - merchant: Merchant name
    ///   - amount: Transaction amount
    /// - Returns: Suggested category
    private func suggestCategory(for merchant: String, amount: Decimal) -> TransactionCategory {
        let lowercasedMerchant = merchant.lowercased()
        
        // Food & Dining
        if lowercasedMerchant.contains("restaurant") || lowercasedMerchant.contains("cafe") ||
           lowercasedMerchant.contains("pizza") || lowercasedMerchant.contains("burger") {
            return TransactionCategory.predefinedCategories[0]
        }
        
        // Transportation
        if lowercasedMerchant.contains("uber") || lowercasedMerchant.contains("lyft") ||
           lowercasedMerchant.contains("gas") || lowercasedMerchant.contains("shell") {
            return TransactionCategory.predefinedCategories[1]
        }
        
        // Shopping
        if lowercasedMerchant.contains("amazon") || lowercasedMerchant.contains("walmart") ||
           lowercasedMerchant.contains("target") || lowercasedMerchant.contains("store") {
            return TransactionCategory.predefinedCategories[2]
        }
        
        // Entertainment
        if lowercasedMerchant.contains("netflix") || lowercasedMerchant.contains("spotify") ||
           lowercasedMerchant.contains("movie") || lowercasedMerchant.contains("theater") {
            return TransactionCategory.predefinedCategories[3]
        }
        
        // Default to "Other"
        return TransactionCategory.predefinedCategories.last!
    }
    
    /// Saves the transaction
    private func saveTransaction() {
        guard isFormValid else { return }
        
        guard let amountValue = Decimal(string: amount),
              let category = selectedCategory,
              let account = selectedAccount else { return }
        
        let newTransaction = Transaction(
            amount: amountValue,
            type: transactionType,
            category: category,
            merchant: merchant,
            date: date,
            account: account,
            notes: notes.isEmpty ? nil : notes,
            receiptImageData: receiptImage?.jpegData(compressionQuality: 0.8),
            location: location,
            priority: priority,
            isRecurring: isRecurring,
            recurringInterval: isRecurring ? recurringInterval : nil,
            tags: tags,
            currency: .usd,
            isAnomaly: false
        )
        
        if let existingTransaction = transaction {
            financeManager.updateTransaction(newTransaction)
        } else {
            financeManager.addTransaction(newTransaction)
        }
        
        dismiss()
    }
    
    /// Form validation
    private var isFormValid: Bool {
        !amount.isEmpty &&
        !merchant.isEmpty &&
        selectedCategory != nil &&
        selectedAccount != nil &&
        Decimal(string: amount) != nil
    }
}

// MARK: - Supporting Views

/// Tag view with remove button
struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

/// Location preview view
struct LocationPreviewView: View {
    let location: Location
    
    var body: some View {
        Map {
            Annotation("Location", coordinate: location.coordinate) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.title)
            }
        }
        .frame(height: 120)
        .cornerRadius(8)
        .allowsHitTesting(false)
    }
}

// MARK: - Validation Errors

/// Form validation error types
enum ValidationError: String, CaseIterable {
    case amount = "Invalid amount"
    case merchant = "Merchant name required"
    case category = "Category required"
    case account = "Account required"
}

// MARK: - Preview Provider

#Preview {
    AddTransactionSheet(financeManager: FinanceManager())
        .preferredColorScheme(.light)
} 