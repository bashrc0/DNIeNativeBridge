# Avisos de terceros

La extensión incorpora los archivos de OpenSCToken (Copyright 2017 Frank Morgner), con licencia GPL-3.0-or-later. El canal seguro CWA 14890, el perfil DNIe y el lector PKCS#15 provienen de OpenSC (LGPL-2.1) y OpenPACE (GPL-3.0). OpenSSL se distribuye bajo Apache-2.0. No se usa ni modifica McDNIe.

- OpenSCToken: https://github.com/frankmorgner/OpenSCToken (commit `85b10be850f1007cc83a2d727e5541f5b28e4674`)
- OpenSC: https://github.com/OpenSC/OpenSC (commit `ccfa7600f7c7ae249118d5f301e679e476a004a5`, versión 0.27.1)
- OpenPACE: tag `1.1.4`, commit `7bc871ab0063c6f1e2443a9b7168262bbe8fa8be`
- OpenSSL: rama `openssl-3.5`, commit `1967268663d6d8d663bdd8cb60a46f4eccdce4cf`
- Los avisos completos están en este directorio. `Sources/` conserva los archivos de código de OpenSSL y OpenPACE; `BuildInputs/OpenSC/` contiene las fuentes de OpenSC usadas para compilar, y `BuildInputs/lib/` e `include/` contienen bibliotecas y cabeceras estáticas usadas por el proyecto.

El componente OpenSCToken es software GPL-3.0-or-later. Si se distribuye la aplicación ya enlazada, deben cumplirse las condiciones de esa licencia, incluidas las relativas al código fuente correspondiente.

## Reconstrucción e integridad

Las bibliotecas estáticas se conservan como entradas de compilación; no contienen una identidad de firma del autor. Las fuentes de OpenSC incluyen el `config.h` generado utilizado por estas entradas. `Sources` conserva los fuentes de OpenPACE y una copia filtrada de OpenSSL de las referencias anteriores; no incluye sus repositorios Git ni registros de compilación.

`SHA256SUMS` identifica los archivos de fuentes archivados y las bibliotecas. Ejecuta `shasum -a 256 -c ThirdParty/SHA256SUMS` desde la raíz para comprobarlos. El script `Scripts/rebuild-dependencies.sh` reconstruye las dependencias incluidas para Intel, con los requisitos y límites documentados en `Docs/BUILD.md`.

OpenSSL corresponde al commit indicado de la rama 3.5; su `VERSION.dat` declara `3.5.10-dev`. Este archivo de fuentes se conserva por trazabilidad y no se presenta como una versión estable publicada. La copia publicada excluye los archivos de pruebas, demostraciones y fuzzing, además de claves de ejemplo de apps, y conserva los archivos build.info para la configuración. El archivo filtrado difiere del original; véase SOURCE-FILTERING.md. La reconstrucción se configura sin tests ni apps.

Los archivos `.gitignore` de las fuentes incorporadas se conservan como `.gitignore.upstream` para que sus reglas no oculten entradas necesarias al publicar este repositorio, en particular el `config.h` de OpenSC. Su contenido original se mantiene.
