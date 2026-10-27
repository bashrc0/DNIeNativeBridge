import CryptoTokenKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ReaderDashboard().tabItem { Label("DNIe", systemImage: "creditcard") }
            CompatibilityView().tabItem { Label("Compatibilidad", systemImage: "checkmark.shield") }
            BrowserToolsView().tabItem { Label("Navegadores", systemImage: "globe") }
        }
        .frame(minWidth: 680, minHeight: 600)
    }
}

private struct ReaderDashboard: View {
    @StateObject private var readerMonitor = ReaderMonitor()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("DNIe nativo para macOS")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Actualizar") {
                    readerMonitor.refresh()
                }
            }

            Text("El controlador de CryptoTokenKit usa OpenSC para abrir el canal seguro CWA 14890 y leer los objetos PKCS#15 del DNIe.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            GroupBox("Acceso de macOS") {
                Text(readerMonitor.accessMessage)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }

            GroupBox("Tokens de CryptoTokenKit") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Button("Comprobar identidades") { readerMonitor.checkIdentities() }
                            .disabled(readerMonitor.isReading || readerMonitor.isCheckingIdentities)
                    }
                    Label(readerMonitor.tokenStatus, systemImage: readerMonitor.tokenCount > 0 ? "checkmark.circle" : "circle.dashed")
                    ForEach(readerMonitor.tokenDetails, id: \.self) { detail in
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Text(readerMonitor.identityStatus)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }

            GroupBox("Canal seguro y certificados") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Button(readerMonitor.isReading ? "Leyendo…" : "Leer certificados") {
                            readerMonitor.readCertificates()
                        }
                        .disabled(readerMonitor.isReading)
                        Text("Prueba local sin PIN").font(.caption).foregroundStyle(.secondary)
                    }
                    Text(readerMonitor.readStatus)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }

            GroupBox("Lectores") {
                if readerMonitor.slots.isEmpty {
                    Text("No se encontraron lectores.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(readerMonitor.slots) { slot in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(slot.name).font(.headline)
                                Text(slot.status).foregroundStyle(.secondary)
                                if let atr = slot.atr {
                                    Text("ATR: \(atr)")
                                        .font(.system(.caption, design: .monospaced))
                                        .textSelection(.enabled)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Spacer(minLength: 0)

            Text("Comprueba las claves con «Comprobar identidades». La conexión solo quedará validada cuando Ivanti complete la firma y establezca el túnel. Introduce el PIN únicamente en el diálogo local de macOS.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 520)
        .onAppear { readerMonitor.refresh() }
    }
}

private struct ReaderSlot: Identifiable {
    let name: String
    let status: String
    let atr: String?

    var id: String { name }
}

@MainActor
private final class ReaderMonitor: ObservableObject {
    @Published private(set) var slots: [ReaderSlot] = []
    @Published private(set) var accessMessage = ""
    @Published private(set) var tokenCount = 0
    @Published private(set) var tokenStatus = "Comprobando tokens registrados…"
    @Published private(set) var tokenDrivers: [String] = []
    @Published private(set) var tokenDetails: [String] = []
    @Published private(set) var readStatus = "Todavía no se ha realizado una lectura de certificados."
    @Published private(set) var isReading = false
    @Published private(set) var isCheckingIdentities = false
    @Published private(set) var identityStatus = "Identidades del sistema sin comprobar."
    private var tokenWatcher: TKTokenWatcher?

    func checkIdentities() {
        guard !isReading, !isCheckingIdentities else { return }
        ensureTokenWatcher()
        let tokenIDs = (tokenWatcher?.tokenIDs ?? []).filter {
            tokenWatcher?.tokenInfo(forTokenID: $0)?.slotName != nil
        }
        isCheckingIdentities = true
        identityStatus = "Consultando identidades con la API Security de macOS…"
        NativeCardReader.inventory(tokenIDs: tokenIDs) { [weak self] summary in
            DispatchQueue.main.async { [weak self] in
                self?.identityStatus = summary
                self?.isCheckingIdentities = false
            }
        }
    }

    func readCertificates() {
        guard !isReading, !isCheckingIdentities else { return }
        guard let manager = TKSmartCardSlotManager.default,
              let slot = manager.slotNames.compactMap({ manager.slotNamed($0) }).first(where: { $0.state == .validCard }) else {
            readStatus = "Inserta un DNIe que responda al lector antes de iniciar la prueba."
            return
        }
        isReading = true
        readStatus = "Abriendo el perfil de la tarjeta y leyendo certificados públicos…"
        NativeCardReader.read(slot: slot, progress: { [weak self] stage in
            DispatchQueue.main.async { [weak self] in self?.readStatus = "\(stage)…" }
        }) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                self?.readStatus = result["message"] as? String ?? "La lectura terminó sin un resultado válido."
                self?.isReading = false
                self?.refreshTokenCount()
            }
        }
    }

    func refresh() {
        ensureTokenWatcher()
        refreshTokenCount()
        guard let manager = TKSmartCardSlotManager.default else {
            slots = []
            accessMessage = "CryptoTokenKit no ha entregado TKSmartCardSlotManager.default. Comprueba que la app esté firmada con el entitlement com.apple.security.smartcard."
            return
        }

        slots = manager.slotNames.sorted().map { name in
            let slot = manager.slotNamed(name)
            return ReaderSlot(
                name: name,
                status: Self.label(for: slot?.state),
                atr: slot?.atr?.bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
            )
        }
        accessMessage = "Acceso CryptoTokenKit disponible. Lector(es) encontrados: \(slots.count)."
    }

    private func ensureTokenWatcher() {
        guard tokenWatcher == nil else { return }
        let watcher = TKTokenWatcher()
        watcher.setInsertionHandler { [weak self] _ in
            DispatchQueue.main.async { [weak self] in self?.refreshTokenCount() }
        }
        tokenWatcher = watcher
    }

    private func refreshTokenCount() {
        let tokenIDs = tokenWatcher?.tokenIDs ?? []
        let infos = tokenIDs.compactMap { tokenWatcher?.tokenInfo(forTokenID: $0) }
        tokenCount = infos.count
        tokenDrivers = Array(Set(infos.compactMap(\.driverName))).sorted()
        tokenDetails = infos.map { info in
            let tokenType = info.tokenID.split(separator: ":", maxSplits: 1).first.map(String.init) ?? info.tokenID
            return "\(info.driverName ?? "Controlador desconocido") · \(info.slotName ?? "lector desconocido") · \(tokenType)"
        }.sorted()
        tokenStatus = tokenCount == 0
            ? "macOS no tiene tokens criptográficos registrados visibles."
            : "macOS muestra \(tokenCount) token(es): \(tokenDrivers.joined(separator: ", "))."
    }

    private static func label(for state: TKSmartCardSlot.State?) -> String {
        switch state {
        case .empty?: return "Lector detectado; sin tarjeta."
        case .probing?: return "Tarjeta insertada; macOS la está identificando."
        case .muteCard?: return "Tarjeta insertada, pero no responde al reinicio."
        case .validCard?: return "Tarjeta insertada y responde al lector."
        case .missing?: return "Lector desconectado."
        case nil: return "Estado del lector no disponible."
        @unknown default: return "Estado nuevo de CryptoTokenKit."
        }
    }
}
