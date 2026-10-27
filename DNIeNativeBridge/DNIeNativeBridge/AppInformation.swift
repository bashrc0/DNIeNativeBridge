import AppKit
import SwiftUI

@MainActor
enum AppInformation {
    static let purpose = "Permite autenticarte con el DNIe y un lector en aplicaciones de macOS compatibles, como Ivanti Secure Access."
    static let contact = "https://github.com/bashrc0/DNIeNativeBridge/issues"

    static func showAbout() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 3
        let text = "\(purpose)\n\nConsultas y sugerencias: \(contact)"
        let credits = NSMutableAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph
        ])
        credits.addAttribute(.link, value: URL(string: contact)!,
                             range: (text as NSString).range(of: contact))
        var options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "DNIeNativeBridge",
            .applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.7",
            .version: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "7",
            .credits: credits
        ]
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            options[.applicationIcon] = icon
        }
        NSApp.orderFrontStandardAboutPanel(options: options)
    }
}

@MainActor
enum AppHelp {
    private static var controller: NSWindowController?

    static func show() {
        if controller == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 390),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Ayuda de DNIeNativeBridge"
            window.collectionBehavior = [.fullScreenNone]
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: HelpView())
            window.center()
            controller = NSWindowController(window: window)
        }
        controller?.showWindow(nil)
        controller?.window?.makeKeyAndOrderFront(nil)
    }
}

private struct HelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cómo usar DNIeNativeBridge")
                .font(.title2.weight(.semibold))
            Text("El puente permite que las aplicaciones compatibles de macOS utilicen tu DNIe a través del lector de tarjetas.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 12) {
                step("1", "Conecta el lector al Mac e introduce el DNIe.")
                step("2", "Pulsa «Actualizar» y comprueba que la tarjeta está detectada. «Comprobar identidades» muestra las claves publicadas por macOS.")
                step("3", "Abre la aplicación compatible, como Ivanti, y conecta con el perfil de tu organización.")
                step("4", "Cuando macOS lo solicite, introduce el PIN del DNIe en el diálogo local.")
            }
            Text("«Leer certificados» es una comprobación opcional del lector. La app no guarda el PIN ni exporta la clave privada del DNIe.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 500, height: 390, alignment: .topLeading)
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.body.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(width: 14, alignment: .leading)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
    }
}
