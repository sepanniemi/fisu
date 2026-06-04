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
        // Local-only storage — CloudKit sync requires a paid developer account.
        // To enable iCloud sync later: change to .private("iCloud.fi.fisu.app")
        // and add the iCloud + Push Notifications capabilities.
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        modelContainer = try! ModelContainer(for: schema, configurations: config)
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
