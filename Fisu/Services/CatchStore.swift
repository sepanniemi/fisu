import Foundation
import SwiftData
import Observation

@Observable @MainActor
final class CatchStore {
    private let context: ModelContext
    private weak var tripRecorder: TripRecorder?

    init(context: ModelContext, tripRecorder: TripRecorder? = nil) {
        self.context = context
        self.tripRecorder = tripRecorder
    }

    @discardableResult
    func create(
        speciesCode: String?,
        speciesCustomName: String? = nil,
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double? = nil,
        timestamp: Date = .now,
        lengthMm: Int? = nil,
        weightGram: Int? = nil,
        released: Bool? = nil,
        lure: String? = nil,
        method: String? = nil,
        notes: String? = nil
    ) -> Catch {
        let entry = Catch()
        entry.speciesCode = speciesCode
        entry.speciesCustomName = speciesCustomName
        entry.latitude = latitude
        entry.longitude = longitude
        entry.horizontalAccuracy = horizontalAccuracy
        entry.timestamp = timestamp
        entry.lengthMm = lengthMm
        entry.weightGram = weightGram
        entry.released = released
        entry.lure = lure
        entry.method = method
        entry.notes = notes
        entry.trip = tripRecorder?.activeTrip
        context.insert(entry)
        return entry
    }

    func delete(_ entry: Catch) {
        context.delete(entry)
    }

    func catches(filter: CatchFilter = .default) throws -> [Catch] {
        let all = try context.fetch(FetchDescriptor<Catch>())
        return filter.apply(to: all)
    }

    func personalBests() throws -> [String: Catch] {
        let all = try context.fetch(FetchDescriptor<Catch>())
        var bests: [String: Catch] = [:]
        for entry in all {
            guard let code = entry.speciesCode else { continue }
            if let existing = bests[code] {
                if CatchFilter.isBigger(entry, than: existing) { bests[code] = entry }
            } else {
                bests[code] = entry
            }
        }
        return bests
    }
}
