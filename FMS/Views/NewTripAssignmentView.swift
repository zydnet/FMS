//
//  NewTripAssignmentView.swift
//  FMS
//
//  Created by NJ on 12/03/26.
//

import SwiftUI
import CoreLocation

// Note: To show interactivity, let's make this view dynamic!
public struct NewTripAssignmentView: View {
    @State private var isConfirmed = false
    @State private var distance: String = "24.5 mi"
    @State private var duration: String = "1h 15m"
    
    // Hardcoded mock data to simulate dynamic fetching
    @State private var activeStops: [MockStop] = [
        MockStop(title: "123 Logistics Way", address: "San Francisco, CA 94105", expectedTime: "09:00 AM Expected", stopType: .pickup, coordinate: CLLocationCoordinate2D(latitude: 37.7876, longitude: -122.3966)),
        MockStop(title: "456 Commerce St", address: "Oakland, CA 94607", expectedTime: "10:15 AM Expected", stopType: .dropOff, coordinate: CLLocationCoordinate2D(latitude: 37.8044, longitude: -122.2712)),
        MockStop(title: "789 Distribution Hub", address: "San Mateo, CA 94401", expectedTime: "11:45 AM Expected", stopType: .pickup, coordinate: CLLocationCoordinate2D(latitude: 37.5630, longitude: -122.3255))
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Map
                    MapCard(stops: activeStops)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    
                    // Stats
                    statsSection
                    
                    // Itinerary
                    itinerarySection
                    
                    // Bottom padding to ensure last item clears the button
                    Spacer().frame(height: 40)
                }
                .padding(16)
            }
            .background(FMSTheme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("New Trip Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        // Dismiss action or equivalent
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .foregroundColor(FMSTheme.textPrimary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomStickyButton
            }
        }
    }
    
    @ViewBuilder
    private var bottomStickyButton: some View {
        let buttonContent = VStack {
            Button(action: {
                withAnimation {
                    isConfirmed.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isConfirmed ? "checkmark.seal.fill" : "checkmark.circle")
                    Text(isConfirmed ? "Trip Assigned" : "Confirm Trip Assignment")
                }
            }
            .buttonStyle(.fmsPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8) // Accommodates safe area
        buttonContent
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(
                        LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .clear]), startPoint: .bottom, endPoint: .top)
                    )
                    .ignoresSafeArea(edges: .bottom)
            )
    }
    
    // Removed headerSection as it is now natively handled by the NavigationBar/Toolbar
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            TripStatCard(
                iconName: "point.topleft.down.curvedto.point.bottomright.up",
                title: "DISTANCE",
                value: distance
            )
            
            TripStatCard(
                iconName: "clock",
                title: "DURATION",
                value: duration
            )
            
            TripStatCard(
                iconName: "123.rectangle",
                title: "STOPS",
                value: "\(activeStops.count) Stops"
            )
        }
    }
    
    private var itinerarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trip Itinerary")
                .font(.title3.weight(.bold))
                .foregroundColor(FMSTheme.textPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(activeStops.enumerated()), id: \.element.id) { index, stop in
                    ItineraryRow(
                        sequenceNumber: index + 1,
                        title: stop.title,
                        address: stop.address,
                        expectedTime: stop.expectedTime,
                        stopType: stop.stopType,
                        isLast: index == activeStops.count - 1
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(FMSTheme.cardBackground)
                    .shadow(color: FMSTheme.shadowLarge, radius: 6, x: 0, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(FMSTheme.borderLight, lineWidth: 0.5)
                    )
            )
        }
    }
}
