# Exclusión de archivos de pruebas criptográficas

Por decisión del proyecto, esta publicación omite archivos que contienen claves privadas de ejemplo, aunque sean muestras públicas de las dependencias. No se han incorporado claves personales ni datos de una tarjeta real.

- OpenSC: se omite `src/tests/regression/test.p12`, un contenedor de pruebas del proyecto original. No interviene en la app ni en las bibliotecas incluidas.
- OpenSSL: el archivo de fuentes excluye los archivos de pruebas, demostraciones y fuzzing (mantiene sus archivos `build.info` para la configuración), además de datos de ejemplo de `apps/` que contienen claves privadas. Conserva los fuentes de las bibliotecas utilizadas, sus cabeceras, configuración, documentación y licencias. El script de reconstrucción utiliza `no-tests` y `no-apps`. Esta copia reducida no permite ejecutar la batería completa de pruebas de OpenSSL.
- OpenPACE: se conserva su archivo de fuentes; no contiene archivos PEM de claves privadas ni contenedores PFX/P12.

Los recursos públicos CVC del DNIe se conservan: son certificados de autoridad, sin clave privada. Las referencias originales y licencias se encuentran en NOTICE.md y ThirdParty/README.md. Los hashes de las copias que se distribuyen están en ThirdParty/SHA256SUMS; el archivo filtrado de OpenSSL difiere del archivo original de ese commit.
