import SwiftUI
import SwiftData

struct CatchesListView: View {
    @Environment(CatchStore.self) private var catchStore
    @Query(sort: \Catch.timestamp, order: .reverse) private var allCatches: [Catch]

    @State private var selectedSpecies: Set<String> = []
    @State private var sortOrder: CatchFilter.SortOrder = .newestFirst
    @State private var personalBests: [String: Catch] = [:]

    private var filter: CatchFilter {
        CatchFilter(
            species: selectedSpecies.isEmpty ? nil : selectedSpecies,
            sortOrder: sortOrder
        )
    }

    private var filtered: [Catch] {
        filter.apply(to: allCatches)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { entry in
                    NavigationLink(value: entry) {
                        CatchRowView(
                            entry: entry,
                            isPersonalBest: personalBests[entry.speciesCode ?? ""]?.id == entry.id
                        )
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet { catchStore.delete(filtered[i]) }
                }
            }
            .navigationTitle("Catches")
            .navigationDestination(for: Catch.self) { entry in
                CatchDetailView(entry: entry)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Section("Sort") {
                            Button("Newest first") { sortOrder = .newestFirst }
                            Button("Biggest first") { sortOrder = .biggestFirst }
                        }
                        Section("Filter species") {
                            ForEach(FishSpeciesCatalog.all) { sp in
                                Button {
                                    if selectedSpecies.contains(sp.code) {
                                        selectedSpecies.remove(sp.code)
                                    } else {
                                        selectedSpecies.insert(sp.code)
                                    }
                                } label: {
                                    Label(sp.nameFI, systemImage: selectedSpecies.contains(sp.code) ? "checkmark" : "")
                                }
                            }
                            if !selectedSpecies.isEmpty {
                                Button("Clear filter") { selectedSpecies = [] }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle\(selectedSpecies.isEmpty ? "" : ".fill")")
                    }
                }
            }
            .task {
                personalBests = (try? catchStore.personalBests()) ?? [:]
            }
            .onChange(of: allCatches.count) { _, _ in
                Task { personalBests = (try? catchStore.personalBests()) ?? [:] }
            }
        }
    }
}
