import SwiftUI
import PhotosUI
import UIKit
import CoreLocation

struct QuickCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CatchStore.self) private var catchStore
    @Environment(LocationService.self) private var locationService
    @Environment(PhotoService.self) private var photoService

    @State private var selectedSpeciesCode: String?
    @State private var customSpecies = ""
    @State private var lengthText = ""
    @State private var weightText = ""
    @State private var released: Bool?
    @State private var lure = ""
    @State private var method = ""
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var thumbnailData: Data?
    @State private var capturedLocation: CLLocation?
    @State private var capturedTime = Date.now

    private let gridColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    contextChips
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    sectionHeader("Species")
                    speciesGrid
                        .padding(.horizontal, 12)

                    if selectedSpeciesCode == "other" {
                        TextField("Species name", text: $customSpecies)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    sectionHeader("Details · optional")
                    optionalFields
                }
            }
            .navigationTitle("New catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(selectedSpeciesCode == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            capturedLocation = locationService.location
            capturedTime = .now
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let pair = await photoService.process(item) {
                    photoData = pair.full
                    thumbnailData = pair.thumb
                }
            }
        }
    }

    private var contextChips: some View {
        HStack(spacing: 8) {
            chip("📍 GPS")
            chip("🕗 \(DateFormatter.fiShort.string(from: capturedTime))")
        }
    }

    private var speciesGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(FishSpeciesCatalog.all) { species in
                Button {
                    selectedSpeciesCode = species.code
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(species.color)
                            .frame(width: 10, height: 10)
                        Text(species.nameFI)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background(
                        selectedSpeciesCode == species.code
                            ? species.color.opacity(0.18)
                            : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 11)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(
                                selectedSpeciesCode == species.code ? species.color : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var optionalFields: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                labeledField("Length (cm)", text: $lengthText, keyboard: .numberPad)
                labeledField("Weight (kg)", text: $weightText, keyboard: .decimalPad)
            }

            Picker("Kept / Released", selection: $released) {
                Text("–").tag(Optional<Bool>.none)
                Text("Kept").tag(Optional<Bool>.some(false))
                Text("Released").tag(Optional<Bool>.some(true))
            }
            .pickerStyle(.segmented)

            labeledField("Lure / bait", text: $lure, keyboard: .default)
            labeledField("Method", text: $method, keyboard: .default)
            labeledField("Notes", text: $notes, keyboard: .default)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(
                    photoData == nil ? "Add photo" : "Change photo",
                    systemImage: photoData == nil ? "camera" : "checkmark.circle.fill"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 11))
            }
            .tint(photoData == nil ? .primary : .green)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    private func labeledField(_ label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(label, text: text)
                .keyboardType(keyboard)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private func save() {
        let lat = capturedLocation?.coordinate.latitude ?? 0
        let lon = capturedLocation?.coordinate.longitude ?? 0
        let acc = capturedLocation?.horizontalAccuracy
        let lengthMm = Int(lengthText.trimmingCharacters(in: .whitespaces)).map { $0 * 10 }
        let weightG = Double(weightText.trimmingCharacters(in: .whitespaces)).map { Int($0 * 1000) }

        let entry = catchStore.create(
            speciesCode: selectedSpeciesCode,
            speciesCustomName: selectedSpeciesCode == "other" ? customSpecies : nil,
            latitude: lat,
            longitude: lon,
            horizontalAccuracy: acc,
            timestamp: capturedTime,
            lengthMm: lengthMm,
            weightGram: weightG,
            released: released,
            lure: lure.isEmpty ? nil : lure,
            method: method.isEmpty ? nil : method,
            notes: notes.isEmpty ? nil : notes
        )
        entry.photoData = photoData
        entry.thumbnailData = thumbnailData
        dismiss()
    }
}
