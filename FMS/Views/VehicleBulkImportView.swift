//
//  VehicleBulkImportView.swift
//  FMS
//
//  Created by Anish on 26/03/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - CSV Template Document
struct CSVTemplateDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var text: String

    init(text: String = "plate_number,manufacturer,model,fuel_type,fuel_tank_capacity,carrying_capacity,status\n") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            text = string
        } else {
            throw CocoaError(.fileReadUnknown)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return .init(regularFileWithContents: data)
    }
}

// MARK: - Main View
public struct VehicleBulkImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = VehicleBulkImportViewModel()
    
    @State private var showingFilePicker = false
    @State private var showingExporter = false
    
    // 1. FIXED: Hold the document in a stable @State variable
    @State private var templateDocument = CSVTemplateDocument()
    
    // Callback to refresh the main fleet view when done
    public var onImportComplete: (() -> Void)?
    
    public init(onImportComplete: (() -> Void)? = nil) {
        self.onImportComplete = onImportComplete
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if viewModel.parsedVehicles.isEmpty && !viewModel.isParsing {
                    instructionState
                } else if viewModel.isParsing {
                    ProgressView("Parsing CSV...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    previewState
                }
            }
            .background(FMSTheme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Bulk Import Vehicles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FMSTheme.textSecondary)
                }
            }
            // Trigger the native iOS Document Picker for uploading
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        viewModel.processCSV(at: url)
                    }
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
            // Trigger the native iOS Document Exporter for downloading the template
            .fileExporter(
                isPresented: $showingExporter,
                document: templateDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "Vehicle_Import_Template.csv"
            ) { result in
                switch result {
                case .success(_):
                    // Optional: Show a success toast here if you like
                    break
                case .failure(let error):
                    viewModel.errorMessage = "Failed to save template: \(error.localizedDescription)"
                }
            }
            .alert("Import Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
        }
    }
    
    // MARK: - Instruction State (UX Revamp)
    private var instructionState: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "list.bullet.clipboard.fill")
                .font(.system(size: 60))
                .foregroundColor(FMSTheme.amber)
            
            VStack(spacing: 16) {
                Text("Import Multiple Vehicles")
                    .font(.title2.weight(.bold))
                    .foregroundColor(FMSTheme.textPrimary)
                
                VStack(alignment: .leading, spacing: 14) {
                    Label("1. Download the blank CSV template.", systemImage: "arrow.down.doc.fill")
                    Label("2. Add your fleet data to the file.", systemImage: "pencil.and.list.clipboard")
                    Label("3. Upload the completed file here.", systemImage: "icloud.and.arrow.up.fill")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(FMSTheme.textSecondary)
                .padding(.top, 8)
            }
            
            VStack(spacing: 16) {
                // Step 1: Download Template
                Button {
                    showingExporter = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Download Template")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(FMSTheme.amber)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(FMSTheme.amber.opacity(0.15))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(FMSTheme.amber.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Step 3: Upload File
                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("Select Completed CSV")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(FMSTheme.obsidian)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(FMSTheme.amber)
                    .cornerRadius(14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            Spacer()
        }
    }
    
    // MARK: - Preview State
    private var previewState: some View {
        VStack(spacing: 0) {
            // Summary Banner
            HStack {
                VStack(alignment: .leading) {
                    Text("Ready to Import")
                        .font(.headline)
                        .foregroundColor(FMSTheme.textPrimary)
                    Text("\(viewModel.parsedVehicles.count) valid vehicles found.")
                        .font(.subheadline)
                        .foregroundColor(FMSTheme.alertGreen)
                    
                    if viewModel.invalidRowCount > 0 {
                        Text("\(viewModel.invalidRowCount) rows ignored (missing plate_number).")
                            .font(.caption)
                            .foregroundColor(FMSTheme.alertOrange)
                    }
                }
                Spacer()
            }
            .padding()
            .background(FMSTheme.cardBackground)
            
            Divider()
            
            // Preview List
            List {
                Section(header: Text("Preview (First 50)")) {
                    ForEach(viewModel.parsedVehicles.prefix(50)) { vehicle in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vehicle.plate_number)
                                    .font(.headline)
                                    .foregroundColor(FMSTheme.textPrimary)
                                Text("\(vehicle.manufacturer ?? "Unknown") \(vehicle.model ?? "")")
                                    .font(.caption)
                                    .foregroundColor(FMSTheme.textSecondary)
                            }
                            Spacer()
                            Text(vehicle.fuel_type?.capitalized ?? "Diesel")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(FMSTheme.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(FMSTheme.borderLight)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            
            // Confirm Button
            VStack {
                Button {
                    viewModel.uploadVehicles {
                        onImportComplete?()
                        dismiss()
                    }
                } label: {
                    HStack {
                        if viewModel.isUploading {
                            ProgressView().tint(FMSTheme.obsidian)
                        } else {
                            Image(systemName: "icloud.and.arrow.up.fill")
                            Text("Confirm & Upload")
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(FMSTheme.obsidian)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(FMSTheme.amber)
                    .cornerRadius(14)
                }
                .disabled(viewModel.isUploading)
                .padding()
            }
            .background(FMSTheme.backgroundPrimary)
        }
    }
}
