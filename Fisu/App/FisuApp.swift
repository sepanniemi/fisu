import SwiftUI
import SwiftData

@main
struct FisuApp: App {
    private let modelContainer: ModelContainer
    private let locationService = LocationService()
    private let tripRecorder: TripRecorder
    private let catchStore: CatchStore
    private let photoService = PhotoService()

    init() {
        let schema = Schema([Catch.self, Trip.self])
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.fi.fisu.app")
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Fallback: local-only when CloudKit is unavailable (simulator without account)
            let fallback = ModelConfiguration(schema: schema)
            modelContainer = try! ModelContainer(for: schema, configurations: fallback)
        }
        let context = modelContainer.mainContext
        tripRecorder = TripRecorder(locationService: locationService, context: context)
        catchStore = CatchStore(context: context, tripRecorder: tripRecorder)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(modelContainer)
                .environment(locationService)
                .environment(tripRecorder)
                .environment(catchStore)
                .environment(photoService)
        }
    }
}
