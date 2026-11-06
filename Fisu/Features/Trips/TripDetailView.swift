import SwiftUI
import MapKit

struct TripDetailView: View {
    let trip: Trip
    @State private var showRename = false
    @State private var newTitle = ""

    private var routePoints: [RoutePoint] {
        guard let data = trip.routeData else { return [] }
        return (try? JSONDecoder().decode([RoutePoint].self, from: data)) ?? []
    }

    private var catches: [Catch] { trip.catches ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                MapContainerView(
                    catches: catches,
                    displayMode: .dots,
                    routePoints: routePoints,
                    apiKey: KeychainStore.mmlApiKey ?? "",
                    onCatchSelected: { _ in },
                    onCatchDeselected: {},
                    framesRoute: true
                )
                .frame(height: 220)

                HStack {
                    statCell("Distance", trip.distanceMeters.map { String(format: "%.1f km", $0 / 1000) } ?? "–")
                    Divider().frame(height: 40)
                    statCell("Duration", durationString)
                    Divider().frame(height: 40)
                    statCell("Fish", "\(catches.count)")
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                Divider()

                if !catches.isEmpty {
                    let grouped = Dictionary(grouping: catches, by: { $0.speciesCode ?? "other" })
                    HStack(spacing: 14) {
                        ForEach(grouped.sorted(by: { $0.value.count > $1.value.count }), id: \.key) { code, entries in
                            HStack(spacing: 4) {
                                Circle().fill(FishSpeciesCatalog.color(for: code)).frame(width: 10, height: 10)
                                Text("\(entries.count) \(FishSpeciesCatalog.displayName(for: code))")
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    Divider()
                }

                if catches.isEmpty {
                    Text("No catches on this trip.")
                        .foregroundStyle(.secondary)
                        .padding(20)
                } else {
                    ForEach(catches.sorted(by: { $0.timestamp < $1.timestamp })) { entry in
                        NavigationLink(destination: CatchDetailView(entry: entry)) {
                            CatchRowView(entry: entry, isPersonalBest: false)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        Divider()
                    }
                }
            }
        }
        .navigationTitle(trip.title ?? "Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Rename") {
                    newTitle = trip.title ?? ""
                    showRename = true
                }
            }
        }
        .alert("Rename trip", isPresented: $showRename) {
            TextField("Trip name", text: $newTitle)
            Button("Save") { trip.title = newTitle }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var durationString: String {
        guard let end = trip.endTime else { return "–" }
        let secs = Int(end.timeIntervalSince(trip.startTime))
        return String(format: "%d:%02d", secs / 3600, (secs % 3600) / 60)
    }

    private func statCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(.green)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
