import SwiftUI
import FamilyControls
import ManagedSettings

// Data model for persisting restrictions
struct SavedRestrictions: Codable {
    let timestamp: Date
    let appCount: Int
    let categoryCount: Int
    let webDomainCount: Int

    init(from selection: FamilyActivitySelection) {
        self.timestamp = Date()
        self.appCount = selection.applicationTokens.count
        self.categoryCount = selection.categoryTokens.count
        self.webDomainCount = selection.webDomainTokens.count
    }
}

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

                    // Show saved restrictions info
                    if let lastSaved = appStore.lastSavedDate, appStore.savedItemCount > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Divider()
                                .padding(.vertical, 8)

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Last Saved Restrictions")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(appStore.savedItemCount) items restricted")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("Saved: \(formattedDate(lastSaved))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

class AppStore: ObservableObject {
    @Published var isAuthorized = false
    @Published var selectionCount = 0
    @Published var lastSavedDate: Date?
    @Published var savedItemCount: Int = 0

    private var selectedApps = FamilyActivitySelection()
    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let restrictionsKey = "savedRestrictions"

    init() {
        checkAuthorization()
        loadSavedRestrictions()
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

                // Save the restrictions data to persistent storage
                saveRestrictions()

                print("Restrictions applied and saved successfully")
            }
        }
    }

    private func saveRestrictions() {
        let restrictions = SavedRestrictions(from: selectedApps)

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(restrictions)
            UserDefaults.standard.set(data, forKey: restrictionsKey)

            // Update published properties
            lastSavedDate = restrictions.timestamp
            savedItemCount = restrictions.appCount + restrictions.categoryCount + restrictions.webDomainCount

            print("Saved restrictions: \(savedItemCount) items at \(restrictions.timestamp)")
        } catch {
            print("Failed to save restrictions: \(error)")
        }
    }

    private func loadSavedRestrictions() {
        guard let data = UserDefaults.standard.data(forKey: restrictionsKey) else {
            print("No saved restrictions found")
            return
        }

        do {
            let decoder = JSONDecoder()
            let restrictions = try decoder.decode(SavedRestrictions.self, from: data)

            lastSavedDate = restrictions.timestamp
            savedItemCount = restrictions.appCount + restrictions.categoryCount + restrictions.webDomainCount

            print("Loaded saved restrictions: \(savedItemCount) items from \(restrictions.timestamp)")
        } catch {
            print("Failed to load restrictions: \(error)")
        }
    }
}

#Preview {
    AppListView()
}
