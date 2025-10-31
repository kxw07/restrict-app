import SwiftUI
import FamilyControls
import ManagedSettings

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

                    if appStore.selectionCount > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Selected Apps: \(appStore.selectionCount)")
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
    @Published var selectionCount = 0

    private var selectedApps = FamilyActivitySelection()
    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()

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
        selectedApps = selection
        selectionCount = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    func applyRestrictions() {
        Task { @MainActor in
            do {
                print("Applying restrictions to \(selectionCount) items")

                // Apply shields to selected apps and categories
                store.shield.applications = selectedApps.applicationTokens

                if !selectedApps.categoryTokens.isEmpty {
                    store.shield.applicationCategories = .specific(selectedApps.categoryTokens)
                }

                if !selectedApps.webDomainTokens.isEmpty {
                    store.shield.webDomains = selectedApps.webDomainTokens
                }

                print("Restrictions applied successfully")
            }
        }
    }
}

#Preview {
    AppListView()
}
