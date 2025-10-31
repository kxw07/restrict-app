import SwiftUI
import FamilyControls
import ManagedSettings

struct RestrictionsDetailView: View {
    @StateObject private var appStore = AppStore()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if appStore.savedItemCount > 0 {
                    // Header with icon
                    VStack(spacing: 15) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Active Restrictions")
                            .font(.title)
                            .fontWeight(.bold)

                        if let lastSaved = appStore.lastSavedDate {
                            Text("Last updated: \(formattedDate(lastSaved))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 30)

                    Divider()
                        .padding(.vertical)

                    // Restrictions summary
                    VStack(spacing: 15) {
                        RestrictionInfoRow(
                            icon: "app.badge",
                            title: "Total Restricted Items",
                            value: "\(appStore.savedItemCount)"
                        )

                        if appStore.savedItemCount > 0 {
                            Text("These apps and categories are currently blocked")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding()

                    Spacer()

                    // Remove restrictions button
                    Button(action: {
                        appStore.removeAllRestrictions()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Remove All Restrictions")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)

                } else {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "shield.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Active Restrictions")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("You haven't set any app restrictions yet. Tap 'Restrict' to get started.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 30)

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Go Back")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Restrictions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RestrictionInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    RestrictionsDetailView()
}
