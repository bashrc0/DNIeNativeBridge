# Autoría, procedencia y licencias

RPastor mantiene DNIeNativeBridge. GPT ha asistido en el desarrollo, la documentación y el diseño del icono. El código propio y las adaptaciones se distribuyen bajo GPL-3.0-or-later. Cada componente de terceros conserva su licencia y sus avisos originales.

| Componente | Referencia del código utilizado | Licencia / avisos |
|---|---|---|
| OpenSCToken, Frank Morgner | `85b10be850f1007cc83a2d727e5541f5b28e4674` | GPL-3.0-or-later; cabeceras originales conservadas |
| OpenSC | `ccfa7600f7c7ae249118d5f301e679e476a004a5`, 0.27.1 | LGPL-2.1 y avisos de sus archivos |
| OpenPACE | `7bc871ab0063c6f1e2443a9b7168262bbe8fa8be`, etiqueta 1.1.4 | GPL-3.0-or-later y permisos adicionales en sus fuentes |
| OpenSSL | `1967268663d6d8d663bdd8cb60a46f4eccdce4cf`, rama 3.5 (`3.5.10-dev` en VERSION.dat) | Apache-2.0 y avisos de sus fuentes |

Las adaptaciones de OpenSCToken se encuentran en los archivos `Token*` de `DNIeNativeBridge/DNIeTokenExtension`. Incluyen el identificador propio del controlador, la selección del DNIe y sus recursos CWA, la publicación de certificados y claves, la compatibilidad de firma RSA con digest SHA, el formato de PIN declarado por la tarjeta y la desactivación de las cachés de PIN y de archivos. Estas modificaciones corresponden al proyecto DNIeNativeBridge, octubre de 2026.

La app anfitriona, sus herramientas y su icono son las aportaciones del proyecto. Los archivos `DESCHSMCVCA00001` y `DESRCACC100001` son recursos públicos de autoridad CVC procedentes de OpenSC, utilizados por el canal seguro; no son certificados personales de un usuario.

Los textos completos de las licencias y los fuentes necesarios de las dependencias se conservan en `ThirdParty`. Esta publicación excluye contenedores de claves de prueba y muestras criptográficas de OpenSSL, aunque sean datos públicos de los proyectos originales. El archivo de fuentes de OpenSSL se ha filtrado y no incluye la batería completa de pruebas, demostraciones o fuzzing. Se conservan sus fuentes de biblioteca; véase `ThirdParty/SOURCE-FILTERING.md`.
