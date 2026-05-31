import SwiftUI
import SwiftData
import UIKit

struct MapScreen: View {
    @Environment(TripRecorder.self) private var recorder
    @Environment(LocationService.self) private var locationService
    @Environment(CatchStore.self) private var catchStore
    @Query private var catches: [Catch]
    @State private var displayMode: CatchDisplayMode = .dots
    @State private var showCapture = false
    @State private var selectedEntry: Catch?
    @State private var navigateToDetail = false
    @State private var showOnboarding = false
    // Stored as @State so changes from Settings force a MapContainerView update.
    @State private var apiKey: String = KeychainStore.mmlApiKey ?? ""

    var body: some View {
        ZStack(alignment: .bottom) {
            MapContainerView(
                catches: displayMode == .hidden ? [] : catches,
                displayMode: displayMode,
                routePoints: recorder.routePoints,
                apiKey: apiKey,
                onCatchSelected: { entry in
                    selectedEntry = entry
                },
                onCatchDeselected: {}
            )
            .ignoresSafeArea()

            // Utility buttons — top right
            VStack(spacing: 10) {
                utilityButton(systemImage: "location.fill") {}
                utilityButton(systemImage: displayMode.iconName) {
                    displayMode.cycle()
                }
            }
            .padding(.trailing, 14)
            .padding(.top, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // Catch overlay card
            if let entry = selectedEntry {
                CatchOverlayCard(
                    entry: entry,
                    onDismiss: { selectedEntry = nil },
                    onOpenDetail: { navigateToDetail = true }
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // FAB + trip bar
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        showCapture = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.red, in: Circle())
                            .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
                    }
                    .padding(.trailing, 14)
                    .padding(.bottom, 8)
                }

                TripBarView()
                    .padding(.horizontal, 14)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            apiKey = KeychainStore.mmlApiKey ?? ""
            locationService.requestWhenInUse()
            if apiKey.isEmpty { showOnboarding = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            apiKey = KeychainStore.mmlApiKey ?? ""
        }
        .onChange(of: locationService.location) { _, location in
            guard let location else { return }
            recorder.appendLocation(location)
        }
        .sheet(isPresented: $showCapture) {
            QuickCaptureSheet()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .navigationDestination(isPresented: $navigateToDetail) {
            if let entry = selectedEntry {
                CatchDetailView(entry: entry)
            }
        }
        .animation(.spring(duration: 0.3), value: selectedEntry?.id)
    }

    private func utilityButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9))
                .shadow(color: .black.opacity(0.18), radius: 4, y: 1)
        }
        .tint(.primary)
    }
}
