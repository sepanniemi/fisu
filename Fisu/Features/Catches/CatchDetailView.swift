import SwiftUI
import UIKit

struct CatchDetailView: View {
    let entry: Catch
    @Environment(CatchStore.self) private var catchStore
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Photo
                if let data = entry.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 160)
                        .overlay(
                            Image(systemName: "fish")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                        )
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(FishSpeciesCatalog.color(for: entry.speciesCode))
                            .frame(width: 14, height: 14)
                        Text(entry.speciesDisplayName)
                            .font(.title2.bold())
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                    if let size = entry.sizeDisplay {
                        Text(size)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                    }

                    Divider().padding(.top, 16)

                    detailRow("When", DateFormatter.fiDateTime.string(from: entry.timestamp))

                    if let rel = entry.released {
                        detailRow("Kept / Released", rel ? "Released" : "Kept")
                    }
                    if let lure = entry.lure, !lure.isEmpty {
                        detailRow("Lure / bait", lure)
                    }
                    if let method = entry.method, !method.isEmpty {
                        detailRow("Method", method)
                    }
                    if let trip = entry.trip, let title = trip.title {
                        detailRow("Trip", title)
                    }

                    if let notes = entry.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text(notes)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        Divider()
                    }
                }
            }
        }
        .navigationTitle(entry.speciesDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            CatchEditView(entry: entry)
        }
        .alert("Delete catch?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                catchStore.delete(entry)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            Divider()
        }
    }
}
