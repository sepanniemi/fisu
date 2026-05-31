import SwiftUI
import PhotosUI

struct CatchEditView: View {
    let entry: Catch
    @Environment(\.dismiss) private var dismiss
    @Environment(PhotoService.self) private var photoService

    @State private var speciesCode: String?
    @State private var customSpecies = ""
    @State private var lengthText = ""
    @State private var weightText = ""
    @State private var released: Bool?
    @State private var lure = ""
    @State private var method = ""
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Species") {
                    Picker("Species", selection: $speciesCode) {
                        Text("–").tag(Optional<String>.none)
                        ForEach(FishSpeciesCatalog.all) { sp in
                            Text(sp.nameFI).tag(Optional<String>.some(sp.code))
                        }
                    }
                    if speciesCode == "other" {
                        TextField("Custom name", text: $customSpecies)
                    }
                }

                Section("Measurements") {
                    TextField("Length (cm)", text: $lengthText)
                        .keyboardType(.numberPad)
                    TextField("Weight (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                }

                Section("Info") {
                    Picker("Kept / Released", selection: $released) {
                        Text("–").tag(Optional<Bool>.none)
                        Text("Kept").tag(Optional<Bool>.some(false))
                        Text("Released").tag(Optional<Bool>.some(true))
                    }
                    TextField("Lure / bait", text: $lure)
                    TextField("Method", text: $method)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(
                            entry.photoData != nil ? "Change photo" : "Add photo",
                            systemImage: "camera"
                        )
                    }
                }
            }
            .navigationTitle("Edit Catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { commitEdits(); dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { loadFromEntry() }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let pair = await photoService.process(item) {
                        entry.photoData = pair.full
                        entry.thumbnailData = pair.thumb
                    }
                }
            }
        }
    }

    private func loadFromEntry() {
        speciesCode = entry.speciesCode
        customSpecies = entry.speciesCustomName ?? ""
        if let mm = entry.lengthMm { lengthText = "\(mm / 10)" }
        if let g = entry.weightGram { weightText = String(format: "%.2f", Double(g) / 1000) }
        released = entry.released
        lure = entry.lure ?? ""
        method = entry.method ?? ""
        notes = entry.notes ?? ""
    }

    private func commitEdits() {
        entry.speciesCode = speciesCode
        entry.speciesCustomName = speciesCode == "other" ? customSpecies : nil
        entry.lengthMm = Int(lengthText).map { $0 * 10 }
        entry.weightGram = Double(weightText).map { Int($0 * 1000) }
        entry.released = released
        entry.lure = lure.isEmpty ? nil : lure
        entry.method = method.isEmpty ? nil : method
        entry.notes = notes.isEmpty ? nil : notes
    }
}
