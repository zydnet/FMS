//
//  AddDriverViewModel.swift
//  FMS
//
//  Created by devanshi on 12/03/26.
//

import Foundation
import Supabase
import Combine

@MainActor
class AddDriverViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var licenseNumber = ""
    @Published var licenseExpiry = Date()
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Role passed in from the tab — not user-selectable
    var role: String
    
    init(role: String = "driver") {
        self.role = role
    }
    
    var isValid: Bool {
        let isNameValid = !name.trimmingCharacters(in: .whitespaces).isEmpty
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        let isEmailValid = emailPredicate.evaluate(with: email)
        
        let isLicenseValid = !licenseNumber.trimmingCharacters(in: .whitespaces).isEmpty
        
        return isNameValid && isEmailValid && isLicenseValid
    }
    
    func createDriver(onSuccess: @escaping () -> Void) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseService.shared.client.auth.session
            let currentUserId = session.user.id.uuidString
            
            struct NewUserPayload: Encodable {
                let name: String
                let email: String
                let phone: String
                let role: String
                let license_number: String
                let license_expiry: String
                let created_by: String
            }
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            
            let payload = NewUserPayload(
                name: name,
                email: email,
                phone: phone,
                role: role,
                license_number: licenseNumber,
                license_expiry: formatter.string(from: licenseExpiry),
                created_by: currentUserId
            )
            
            // Calls Edge Function — NOT direct DB insert
            try await SupabaseService.shared.client.functions
                .invoke(
                    "create-user",
                    options: FunctionInvokeOptions(body: payload)
                )
            
            onSuccess()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
