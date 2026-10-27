# Compilación

## Línea de comandos

Requisitos: macOS, Python 3, Command Line Tools con Swift 6.1 y SDK macOS 15.5 o posterior. El objetivo de esta publicación es Intel (`x86_64-apple-macosx15.5`).

Desde la raíz del repositorio:

```sh
python3 Scripts/build.py
```

La salida es `build/DNIeNativeBridge.app`. El script compila el lector, la app Swift y la extensión Objective-C, copia los recursos públicos del canal CWA y genera el ICNS a partir del catálogo aprobado. Firma primero la extensión y después el anfitrión. No registra ni ejecuta ninguno de ellos y no accede al DNIe.

La identidad predeterminada es ad hoc (`-`), útil para verificar compilación y empaquetado. Para usar el controlador, compila con una identidad válida instalada en tu llavero:

```sh
python3 Scripts/build.py --identity 'NOMBRE DE TU IDENTIDAD DE FIRMA'
```

`security find-identity -v -p codesigning` permite consultar las identidades disponibles. La clave de firma y sus autorizaciones permanecen en el llavero de cada desarrollador. Una compilación ad hoc no equivale a una distribución pública ni acredita que CryptoTokenKit vaya a cargar el token.

## Xcode

Abre `DNIeNativeBridge/DNIeNativeBridge.xcodeproj` con Xcode 16.4 o posterior. Selecciona tu equipo en Signing & Capabilities para ambos destinos. El esquema compartido es `DNIeNativeBridge`; la arquitectura publicada está fijada a Intel. Las rutas de las dependencias son relativas al proyecto.

No hay cuentas, certificados de firma ni perfiles de aprovisionamiento incluidos. La recompilación de la extensión genera una firma nueva y requiere su registro y una prueba física antes de darla por validada.

## Dependencias

`ThirdParty/BuildInputs` conserva las fuentes/cabeceras y bibliotecas estáticas que utiliza el proyecto. Los archivos `.a` se mantienen expresamente porque Xcode los necesita. Las fuentes completas de OpenPACE y OpenSSL están archivadas en `ThirdParty/Sources`; las de OpenSC están en `ThirdParty/BuildInputs/OpenSC`. La copia de OpenSSL excluye material de pruebas/demostración y se reconstruye con `no-tests`; véase `ThirdParty/SOURCE-FILTERING.md`.

Para reconstruir esas bibliotecas existe `Scripts/rebuild-dependencies.sh`. Necesita además Autoconf, Automake, GNU Libtool, pkg-config y gengetopt. Trabaja en `build/dependencies`, no instala herramientas globalmente y usa las fuentes incluidas, sin descargar otras versiones. Esta ruta de reconstrucción de dependencias no se ha ejecutado de nuevo al preparar la publicación; las bibliotecas incluidas son las utilizadas por la versión validada. Los hashes de las dependencias están en `ThirdParty/SHA256SUMS`.

## Empaquetado

```sh
python3 Scripts/package.py --app build/DNIeNativeBridge.app
```

La salida se guarda en `dist`. El script verifica la firma de la app y genera un instalador Intel con registro de la extensión y actualización de la fecha del paquete para que Launchpad detecte el icono. No lo instala ni lo ejecuta. Una firma de desarrollo o ad hoc no sustituye Developer ID y notarización para distribución general. El repositorio no incluye instaladores ni apps ya firmadas.

## Pruebas sin tarjeta

```sh
python3 Scripts/test.py
```

Verifican el rechazo de RSA-PSS cuando el controlador solo permite PKCS#1 y comprueban el relleno PSS de OpenSC frente a Security.framework para SHA-256/384/512, con una clave RSA efímera creada en memoria. Comprueban asimismo que solo la etiqueta de autenticación del proveedor puede seleccionarse para la prueba local, sin confundir nombres de titulares ni certificados de firma. También validan la normalización del servidor HTTPS y el entrecomillado del script de Safari. No consultan el llavero, no acceden a una tarjeta ni piden PIN. No sustituyen la prueba física.
