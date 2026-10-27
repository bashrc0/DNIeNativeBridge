import AppKit
import SwiftUI

struct BrowserToolsView: View {
    @State private var address = ""
    @State private var message = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Elegir certificado en el navegador").font(.title2.weight(.semibold))
                Text("El DNIe y un certificado FNMT pueden coexistir. En el selector de certificados, elige «Autenticación» para identificarte con el DNIe o el certificado FNMT para utilizar el llavero.")
                GroupBox("Safari") {
                    VStack(alignment: .leading, spacing: 13) {
                        Text("Safari puede recordar un certificado para un servidor y utilizarlo en accesos posteriores. Puedes restablecer esa elección sin borrar ni sustituir certificados.")
                        TextField("https://sitio-web.example", text: $address)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Dirección HTTPS del sitio web")
                        HStack {
                            Button("Abrir en Safari") { openSafari() }
                            Button("Guardar herramienta para volver a elegir…") { saveResetTool() }
                        }
                        Text("La herramienta se guarda donde tú elijas y se ejecuta localmente con doble clic. Solo afecta a la preferencia de Safari para ese servidor; no cambia otros programas ni sus certificados.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }.padding(.vertical, 8)
                }
                GroupBox("Una sesión nueva") {
                    Text("En Safari puedes usar Archivo → Nueva ventana privada para probar con una sesión separada. Al volver a elegir certificado, selecciona la autenticación del DNIe. Si la web requiere RSA-PSS y no está disponible en «Compatibilidad», la selección puede mostrarse y la firma aun así fallar antes del PIN.")
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                }
                GroupBox("Otras aplicaciones") {
                    Text("Ivanti y las aplicaciones que utilizan las identidades del sistema acceden al puente mediante CryptoTokenKit. Los programas que usan exclusivamente PKCS#11 necesitan su propio módulo y configuración. Esta app no modifica automáticamente los perfiles de VPN, las preferencias del navegador ni la confianza de los certificados.")
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                }
                Text(message).font(.callout).textSelection(.enabled)
            }.padding(24)
        }
    }

    private func openSafari() {
        do {
            _ = try SafariChoiceSupport.service(for: address)
            guard let url = URL(string: address.trimmingCharacters(in: .whitespacesAndNewlines)),
                  let application = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") else { return }
            NSWorkspace.shared.open([url], withApplicationAt: application, configuration: NSWorkspace.OpenConfiguration())
        } catch { message = error.localizedDescription }
    }

    private func saveResetTool() {
        do {
            let script = try SafariChoiceSupport.script(for: address)
            let panel = NSSavePanel()
            panel.title = "Guardar herramienta de elección de Safari"
            panel.nameFieldStringValue = "Restablecer-eleccion-Safari.command"
            panel.message = "Solo restablece la preferencia de Safari para el servidor indicado. No elimina certificados."
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try script.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
            NSWorkspace.shared.activateFileViewerSelecting([url])
            message = "Herramienta guardada. Ábrela con doble clic cuando quieras quitar la elección recordada de ese servidor."
        } catch { message = error.localizedDescription }
    }
}
