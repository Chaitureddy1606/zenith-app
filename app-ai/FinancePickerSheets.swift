//
//  FinancePickerSheets.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import SwiftUI
import MapKit
import PhotosUI
import UIKit

// MARK: - Category Picker Sheet

/// Sheet for selecting transaction categories with visual grid layout
struct CategoryPickerSheet: View {
    @Binding var selectedCategory: TransactionCategory?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(TransactionCategory.predefinedCategories) { category in
                        CategoryOptionView(
                            category: category,
                            isSelected: selectedCategory?.id == category.id
                        ) {
                            selectedCategory = category
                            dismiss()
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }
}

/// Individual category option view
struct CategoryOptionView: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.title)
                    .foregroundColor(category.color)
                    .frame(width: 44, height: 44)
                    .background(category.color.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
                    )
                
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? category.color : Color.primary.opacity(0.1), lineWidth: isSelected ? 2 : 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel(category.name)
        .accessibilityHint("Tap to select \(category.name) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Account Picker Sheet

/// Sheet for selecting financial accounts
struct AccountPickerSheet: View {
    @Binding var selectedAccount: Account?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var financeManager: FinanceManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(financeManager.accounts) { account in
                    AccountOptionView(
                        account: account,
                        isSelected: selectedAccount?.id == account.id
                    ) {
                        selectedAccount = account
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// Individual account option view
struct AccountOptionView: View {
    let account: Account
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: account.type.iconName)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(account.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.formattedBalance)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(account.balance >= 0 ? .green : .red)
                    
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(account.name), \(account.type.displayName), Balance: \(account.formattedBalance)")
        .accessibilityHint("Tap to select \(account.name) account")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Location Picker Sheet

/// Sheet for selecting and managing transaction locations
struct FinanceLocationPickerSheet: View {
    @Binding var location: Location?
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Map view
                mapView
                
                // Search results
                if !searchResults.isEmpty {
                    searchResultsList
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveLocation()
                        dismiss()
                    }
                    .disabled(selectedMapItem == nil)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    /// Search bar for location search
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search for a location...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    searchLocations()
                }
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                    searchResults = []
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    /// Map view for location selection
    private var mapView: some View {
        Map {
            ForEach(mapAnnotations, id: \.id) { annotation in
                Annotation("Location", coordinate: annotation.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title)
                }
            }
        }
        .onTapGesture {
            // Handle map tap to select location
            selectLocationAt(coordinate: region.center)
        }
    }
    
    /// Map annotations for display
    private var mapAnnotations: [FinanceMapAnnotation] {
        var annotations: [FinanceMapAnnotation] = []
        
        if let selectedMapItem = selectedMapItem {
            annotations.append(FinanceMapAnnotation(
                coordinate: selectedMapItem.placemark.coordinate
            ))
        }
        
        return annotations
    }
    
    /// Search results list
    private var searchResultsList: some View {
        List(searchResults, id: \.self) { mapItem in
            Button {
                selectMapItem(mapItem)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mapItem.name ?? "Unknown Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let address = mapItem.placemark.thoroughfare {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxHeight: 200)
    }
    
    /// Searches for locations based on search text
    private func searchLocations() {
        guard !searchText.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            
            DispatchQueue.main.async {
                searchResults = response.mapItems
            }
        }
    }
    
    /// Selects a map item from search results
    private func selectMapItem(_ mapItem: MKMapItem) {
        selectedMapItem = mapItem
        
        // Update map region to show selected location
        let coordinate = mapItem.placemark.coordinate
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        // Clear search results
        searchResults = []
        searchText = mapItem.name ?? ""
    }
    
    /// Selects location at specific coordinate
    private func selectLocationAt(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }
            
            DispatchQueue.main.async {
                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                selectMapItem(mapItem)
            }
        }
    }
    
    /// Saves the selected location
    private func saveLocation() {
        guard let mapItem = selectedMapItem else { return }
        
        let coordinate = mapItem.placemark.coordinate
        let name = mapItem.name
        let address = [
            mapItem.placemark.thoroughfare,
            mapItem.placemark.locality,
            mapItem.placemark.administrativeArea
        ].compactMap { $0 }.joined(separator: ", ")
        
        location = Location(
            coordinate: coordinate,
            name: name,
            address: address.isEmpty ? nil : address
        )
    }
}

/// Map annotation model for finance
struct FinanceMapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Photo Picker

/// Photo picker for receipt images
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Camera View

/// Camera view for taking receipt photos
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview Provider

#Preview {
    CategoryPickerSheet(selectedCategory: .constant(nil))
        .preferredColorScheme(.light)
} 