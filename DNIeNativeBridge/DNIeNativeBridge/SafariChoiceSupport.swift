import Foundation

/// Builds only an origin-scoped reset of Safari's remembered identity choice.
/// It never stores a certificate, private key or PIN and never runs the command.
enum SafariChoiceSupport {
    enum InputError: LocalizedError {
        case invalidURL
        var errorDescription: String? { "Introduce una dirección HTTPS válida, sin usuario ni contraseña." }
    }

    static func service(for input: String) throws -> String {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parts = URLComponents(string: value), parts.scheme?.lowercased() == "https",
              let host = parts.host, !host.isEmpty, parts.user == nil, parts.password == nil,
              !host.contains(where: { $0.isWhitespace || $0.isNewline }),
              (1...65535).contains(parts.port ?? 443) else { throw InputError.invalidURL }
        var origin = URLComponents()
        origin.scheme = "https"
        origin.host = host.lowercased()
        origin.port = parts.port ?? 443
        guard let address = origin.string else { throw InputError.invalidURL }
        return address + " (com.apple.Safari)"
    }

    static func shellQuote(_ value: String) -> String { "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'" }

    static func script(for input: String) throws -> String {
        let target = try service(for: input)
        return """
        #!/bin/bash
        # DNIeNativeBridge: reset only the chosen Safari identity preference.
        set -u
        DNIE_SERVICE=\(shellQuote(target))
        echo 'Restablecer la elección de certificado de Safari'
        printf 'Servidor: %s\\n' "$DNIE_SERVICE"
        echo 'Solo se elimina la preferencia automática; se conservan certificados y claves.'
        echo
        if /usr/bin/security find-generic-password -s "$DNIE_SERVICE" -C iprf >/dev/null 2>&1; then
            /usr/bin/security set-identity-preference -n -s "$DNIE_SERVICE"
            if /usr/bin/security find-generic-password -s "$DNIE_SERVICE" -C iprf >/dev/null 2>&1; then
                echo 'La preferencia sigue presente. No se ha borrado ningún certificado.'
            else
                echo 'Preferencia eliminada correctamente.'
            fi
        else
            echo 'No existe una preferencia automática para ese servidor.'
        fi
        echo 'Cierra Safari y abre una sesión nueva para volver a elegir.'
        echo 'Safari puede recordar una elección posterior. Una ventana privada permite probar en otra sesión.'
        echo
        read -r -p 'Pulsa Intro para cerrar.' DNIE_CLOSE
        """ + "\n"
    }
}
