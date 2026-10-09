import SwiftUI

@main
struct RemindersApp: App {

    @State private var store = ItemStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
