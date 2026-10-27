import CryptoTokenKit
import SwiftUI

struct CompatibilityView: View {
    @StateObject private var model = CompatibilityMonitor()
    @State private var usePSS = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Compatibilidad con aplicaciones").font(.title2.weight(.semibold))
                    Spacer()
                    Button("Comprobar compatibilidad") { model.refresh() }.disabled(model.busy)
                }
                Text("Las aplicaciones que utilizan las identidades de macOS pueden acceder al DNIe mediante este puente. La firma también depende del algoritmo que solicite cada aplicación.")
                    .foregroundStyle(.secondary)
                GroupBox("Identidades disponibles") {
                    Text(model.checked ? "\(model.count("identities")) identidades y \(model.count("keys")) claves del DNIe publicadas en macOS." : "Comprueba la compatibilidad con el DNIe insertado.")
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 5)
                }
                GroupBox("Algoritmos de firma") {
                    VStack(spacing: 9) {
                        capability("RSA PKCS#1 · SHA-256", key: "pkcs1SHA256")
                        capability("RSA PKCS#1 · SHA-384", key: "pkcs1SHA384")
                        capability("RSA PKCS#1 · SHA-512", key: "pkcs1SHA512")
                        Divider()
                        capability("RSA-PSS · SHA-256", key: "pssSHA256")
                        capability("RSA-PSS · SHA-384", key: "pssSHA384")
                        capability("RSA-PSS · SHA-512", key: "pssSHA512")
                    }.padding(.vertical, 7)
                }
                if model.checked && model.count("keys") > 0 && model.count("pssSHA256") == 0 {
                    Label("El proveedor actual no admite RSA-PSS con este DNIe. Una aplicación que elija ese algoritmo puede fallar antes de solicitar el PIN, aunque muestre el certificado.", systemImage: "info.circle")
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                GroupBox("Prueba local de autenticación") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Firma un reto aleatorio con la clave de autenticación y verifica el resultado con su clave pública. No realiza trámites ni envía datos a una web.")
                        HStack {
                            Picker("Algoritmo", selection: $usePSS) {
                                Text("RSA PKCS#1 · SHA-256").tag(false)
                                Text("RSA-PSS · SHA-256").tag(true)
                            }.frame(maxWidth: 360)
                            Button("Probar firma") { model.test(pss: usePSS) }
                                .disabled(model.busy || model.count("keys") == 0 || (usePSS && model.count("pssSHA256") == 0))
                        }
                        Text(model.testMessage).font(.callout).textSelection(.enabled)
                        Text("Solo esta prueba puede solicitar el PIN, mediante el diálogo local de macOS. No se repite automáticamente.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }.padding(.vertical, 6)
                }
                if !model.status.isEmpty { Text(model.status).font(.footnote).foregroundStyle(.secondary) }
            }.padding(24)
        }.onAppear { if !model.checked { model.refresh() } }
    }

    private func capability(_ title: String, key: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            if !model.checked {
                Text("Sin comprobar").foregroundStyle(.secondary)
            } else if model.count(key) > 0 {
                Label("Disponible en \(model.count(key)) claves", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            } else {
                Label("No disponible", systemImage: "minus.circle").foregroundStyle(.secondary)
            }
        }
    }
}

@MainActor
private final class CompatibilityMonitor: ObservableObject {
    @Published private(set) var report: [String: Any] = [:]
    @Published private(set) var busy = false
    @Published private(set) var checked = false
    @Published private(set) var status = ""
    @Published private(set) var testMessage = "La prueba todavía no se ha realizado."
    private let watcher = TKTokenWatcher()
    private var refreshPending = false

    init() {
        watcher.setInsertionHandler { [weak self] tokenID in
            guard tokenID.hasPrefix("es.local.DNIeNativeBridge.") else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.watcher.addRemovalHandler({ [weak self] _ in
                    DispatchQueue.main.async { [weak self] in self?.refresh() }
                }, forTokenID: tokenID)
                self.refresh()
            }
        }
    }

    private func finishRefreshIfNeeded() {
        if refreshPending {
            refreshPending = false
            refresh()
        }
    }
    private var tokenIDs: [String] { watcher.tokenIDs.filter { $0.hasPrefix("es.local.DNIeNativeBridge.") } }
    func count(_ key: String) -> Int { (report[key] as? NSNumber)?.intValue ?? 0 }

    func refresh() {
        guard !busy else { refreshPending = true; return }
        busy = true
        status = "Consultando capacidades sin solicitar el PIN…"
        NativeCardReader.compatibility(tokenIDs: tokenIDs) { [weak self] report in
            guard let self else { return }
            self.report = report
            self.checked = true
            self.busy = false
            self.status = self.count("keys") > 0 ? "La disponibilidad se obtiene de las claves que macOS entrega a las aplicaciones; no garantiza el acceso a todas las webs." : "No hay claves del puente disponibles. Comprueba el lector, la tarjeta y el registro de la extensión."
            self.finishRefreshIfNeeded()
        }
    }

    func test(pss: Bool) {
        guard !busy else { return }
        busy = true
        testMessage = "Prueba en curso. Si macOS solicita el PIN, introdúcelo únicamente en su diálogo local."
        NativeCardReader.testAuthentication(tokenIDs: tokenIDs, pss: pss) { [weak self] result in
            self?.testMessage = result["message"] as? String ?? "La prueba no ha devuelto un resultado."
            self?.busy = false
            self?.finishRefreshIfNeeded()
        }
    }
}
