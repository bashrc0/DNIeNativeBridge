//
//  DNIeNativeBridgeApp.swift
//  DNIeNativeBridge
//
//  DNIeNativeBridge - RPastor, con asistencia de GPT.
//

import AppKit
import SwiftUI

@main
struct DNIeNativeBridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .windowFullScreenBehavior(.disabled)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Acerca de DNIeNativeBridge") {
                    AppInformation.showAbout()
                }
            }
            CommandGroup(replacing: .help) {
                Button("Ayuda de DNIeNativeBridge") {
                    AppHelp.show()
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }
}

/// Apple requires the host app to be launched as `_securityagent` once so
/// Launch Services registers the CryptoTokenKit extension. This argument lets
/// that launch exit before SwiftUI creates a window in the agent's session.
private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        let registrationLaunch = CommandLine.arguments.contains("-shouldQuitImmediately")
            || UserDefaults.standard.bool(forKey: "shouldQuitImmediately")
        guard registrationLaunch else { return }
        exit(EXIT_SUCCESS)
    }
}
