//
//  EliteApp.swift
//  Elite
//
//  App entry point. Sets the global appearance to a dark, iOS 26
//  "Liquid Glass" style and bootstraps the main signing screen.
//

import SwiftUI

@main
struct EliteApp: App {
    // Shared app-wide state holding the user-provided files & password.
    @StateObject private var session = SigningSession()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
    }
}
