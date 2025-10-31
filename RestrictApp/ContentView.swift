import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Restrict App")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Take control of your time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
                    .frame(height: 50)

                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "clock.fill", title: "Track App Usage", description: "Monitor time spent on apps")
                    FeatureRow(icon: "lock.fill", title: "Set Limits", description: "Restrict access to distracting apps")
                    FeatureRow(icon: "chart.bar.fill", title: "View Statistics", description: "Analyze your usage patterns")
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Welcome")
            .padding()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
