//
//  OrdersViewModel.swift
//  FMS
//
//  Created by user@50 on 16/03/26.
//


import Foundation
import Observation
import Supabase

@Observable
public final class OrdersViewModel {
    
    // MARK: - State
    public var allOrders: [Order] = []
    
    public var isLoading: Bool = false
    public var isCreating: Bool = false
    public var errorMessage: String? = nil
    
    // MARK: - Computed Filters
    public var pendingOrders: [Order] {
        allOrders.filter { $0.isPending }.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
    }
    
    public var ongoingOrders: [Order] {
        allOrders.filter { $0.isOngoing }.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
    }
    
    public var completedOrders: [Order] {
        allOrders.filter { $0.isCompleted }.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
    }
    
    public init() {}
    
    // MARK: - Fetch Orders
    @MainActor
    public func fetchOrders() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [Order] = try await SupabaseService.shared.client
                .from("orders")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.allOrders = response
            
        } catch {
            print("Orders Fetch Error: \(error)")
            self.errorMessage = "Failed to load orders: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Create Order
    @MainActor
    public func createOrder(payload: OrderCreatePayload) async -> Bool {
        isCreating = true
        errorMessage = nil
        
        do {
            let _: Order = try await SupabaseService.shared.client
                .from("orders")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            
            await fetchOrders()
            
            isCreating = false
            return true
            
        } catch {
            print("Order Creation Error: \(error)")
            self.errorMessage = "Failed to create order: \(error.localizedDescription)"
            isCreating = false
            return false
        }
    }
}

