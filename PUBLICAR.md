# Publicar DNIeNativeBridge 1.0.7 en GitHub

Esta carpeta es la raíz del repositorio. Contiene las fuentes de la app y la extensión, el icono azul, dependencias con sus fuentes y licencias, documentación y pruebas. No incluye certificados personales, perfiles VPN, registros ni una identidad de firma preconfigurada.

## Crear el repositorio

Crea en GitHub un repositorio vacío llamado `DNIeNativeBridge`. Desde Terminal, situado en esta carpeta:

```sh
git init -b main
git config user.name "RPastor"
git config user.email "139147850+bashrc0@users.noreply.github.com"
git add .
git commit -m "Publicación inicial de DNIeNativeBridge 1.0.7"
```

Añade después como `origin` la URL de tu repositorio y sube `main`. El repositorio oficial es https://github.com/bashrc0/DNIeNativeBridge. Estas instrucciones sirven también para crear una copia propia.

Conserva los archivos ocultos `.gitignore` y `.gitignore.upstream`. No añadas tus certificados de firma, credenciales, datos del DNIe ni resultados de pruebas personales. Las muestras criptográficas públicas de las dependencias están identificadas en NOTICE.md.

## Versión e instalador

La interfaz es 1.0.7 (7) y la extensión 1.0.7 (6). Crea una etiqueta `v1.0.7` sobre la versión publicada y adjunta el instalador como archivo de una release, separado del árbol de fuentes. La carpeta del instalador incluye sus fuentes correspondientes y hashes SHA-256.

El paquete preparado es para Mac Intel con macOS 15.5 o posterior. Su app tiene firma de desarrollo; el paquete no está firmado con Developer ID Installer ni notarizado. Antes de ofrecer una descarga binaria final para otros equipos, prepara la firma y notarización de distribución.

## Alcance comprobado

La prueba local de autenticación RSA PKCS#1/SHA-256 con DNIe y verificación de firma se completó correctamente en el equipo de desarrollo. No se afirma que todos los navegadores sean compatibles: el acceso de Safari que solicita RSA-PSS sigue pendiente. Los detalles están en Docs/VALIDATION.md y Docs/COMPATIBILITY.md.

Para compilar y ejecutar las pruebas, consulta Docs/BUILD.md. Los archivos se preparan para publicar, sin modificar ni incluir el historial de esta sesión.
