import SwiftUI
import FamilyControls

struct AppListView: View {
    @StateObject private var appStore = AppStore()
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if appStore.isAuthorized {
                    FamilyActivityPicker(selection: $selection)
                        .onChange(of: selection) { newSelection in
                            appStore.updateSelection(newSelection)
                        }

                    if !appStore.selectedApps.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Selected Apps: \(appStore.selectedApps.count)")
                                .font(.headline)
                                .padding(.horizontal)

                            Button(action: {
                                appStore.applyRestrictions()
                            }) {
                                Text("Apply Restrictions")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text("Authorization Required")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("This app needs permission to access Screen Time data to help you restrict app usage.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 30)

                        Button(action: {
                            appStore.requestAuthorization()
                        }) {
                            Text("Grant Permission")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Select Apps")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

class AppStore: ObservableObject {
    @Published var isAuthorized = false
    @Published var selectedApps: [String] = []

    private let center = AuthorizationCenter.shared

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }

    func requestAuthorization() {
        Task {
            do {
                try await center.requestAuthorization(for: .individual)
                await MainActor.run {
                    checkAuthorization()
                }
            } catch {
                print("Failed to authorize: \(error)")
            }
        }
    }

    func updateSelection(_ selection: FamilyActivitySelection) {
        selectedApps = Array(selection.applicationTokens.map { $0.description })
    }

    func applyRestrictions() {
        // This is where you would apply the actual restrictions
        // using ManagedSettings or DeviceActivity
        print("Applying restrictions to \(selectedApps.count) apps")
    }
}

#Preview {
    AppListView()
}
