import SwiftUI
import SwiftData

struct TripsListView: View {
    @Query(sort: \Trip.startTime, order: .reverse) private var trips: [Trip]
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            List {
                ForEach(trips) { trip in
                    NavigationLink(value: trip) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.title ?? "Trip")
                                .font(.subheadline.weight(.bold))
                            HStack(spacing: 6) {
                                Text(DateFormatter.fiDateTime.string(from: trip.startTime))
                                if let km = trip.distanceMeters {
                                    Text("·")
                                    Text(String(format: "%.1f km", km / 1000))
                                }
                                Text("·")
                                Text("\(trip.catches?.count ?? 0) fish")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet { context.delete(trips[i]) }
                }
            }
            .navigationTitle("Trips")
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .overlay {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "No trips yet",
                        systemImage: "map",
                        description: Text("Start a trip from the map to record your route.")
                    )
                }
            }
        }
    }
}
