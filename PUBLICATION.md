# Carpeta preparada para publicar

Preparación: 27/10/2026. Versión de la interfaz: 1.0.7 (7); extensión: 1.0.7 (6).

## Incluido

- Proyecto Xcode, esquema compartido, código Swift/Objective-C, entitlements y recursos públicos del controlador.
- Catálogo del escudo azul y su imagen de origen seleccionada.
- Fuentes, cabeceras, bibliotecas estáticas y avisos de terceros, con referencias y hashes.
- Licencia GPL-3.0-or-later para el código propio y las adaptaciones; licencias originales de terceros conservadas.
- Guías de compilación, uso, contribución, pruebas y contacto.
- Scripts de compilación y empaquetado que no dependen de una app instalada ni incluyen la identidad de firma del autor.

## Excluido

No se han copiado las apps compiladas, instaladores, copias de seguridad, cachés de compilación, registros de las sesiones, propuestas de icono descartadas, prototipos antiguos, metadatos de Git ni preferencias personales de Xcode. Se ha eliminado el equipo de desarrollo preasignado del proyecto.

No se incluyen los certificados personales del usuario, archivos FNMT, PIN, perfiles de VPN, direcciones de portales corporativos ni el contenido de consultas o mensajes. El contacto personal del autor se ha retirado de la publicación; las consultas se canalizan mediante GitHub. Los avisos de autoría públicos de las dependencias también se conservan.

Las bibliotecas `.a` se incluyen expresamente como entradas de compilación, junto con sus fuentes. Los recursos CVC del DNIe son certificados públicos de autoridad sin clave privada. Se han excluido el contenedor test.p12 de OpenSC y los archivos de pruebas, demostraciones y fuzzing de OpenSSL, así como sus archivos de claves de ejemplo. Véanse NOTICE.md y ThirdParty/SOURCE-FILTERING.md.

## Comprobaciones realizadas

1. Compilación completa del anfitrión y de la extensión desde esta copia, con las Command Line Tools y firma ad hoc. Verificación estricta de la firma de ambos paquetes completada.
2. Generación de un instalador con los scripts publicados. Extracción y verificación de su app completadas. El instalador no se ejecutó ni se incluye en esta carpeta.
3. Verificación de los hashes de los archivos de fuentes y bibliotecas de terceros.
4. Análisis sintáctico del proyecto, scripts Python y scripts del instalador.
5. Búsqueda de rutas locales e identificadores de firma del entorno original, referencias a los portales y datos de sesión conocidos, en los archivos y en las fuentes archivadas: sin coincidencias.
6. Comprobación con un índice temporal de Git de que no hay archivos necesarios ocultos por las reglas de exclusión. El índice y los resultados de compilación quedaron fuera de esta carpeta.

El script para reconstruir las dependencias desde sus fuentes se ha comprobado sintácticamente, pero no se ha ejecutado de nuevo. La ruta de compilación por Xcode tampoco se ha ejecutado en esta preparación; sí la compilación independiente por línea de comandos.

La versión 1.0.7 se ha instalado en el equipo de desarrollo. Se ha probado la interfaz nueva y la exportación del helper de Safari. Se ha comprobado la publicación de dos identidades y dos claves tras reinsertar la tarjeta. La prueba física local RSA PKCS#1/SHA-256 se completó con PIN introducido por el usuario y verificación correcta de la firma. Esa prueba no acredita una conexión nueva de Ivanti ni compatibilidad RSA-PSS. Las comprobaciones automatizadas de RSA-PSS y del helper pasan. El acceso de Safari que requiere PSS continúa sin resolver; véanse Docs/VALIDATION.md y Docs/COMPATIBILITY.md.

## Publicación

Esta carpeta contiene el código de la publicación inicial, con un historial nuevo que excluye las copias anteriores a la limpieza. Repositorio: https://github.com/bashrc0/DNIeNativeBridge. Utiliza su contenido como raíz del nuevo repositorio y conserva los archivos ocultos `.gitignore` y `.gitignore.upstream` de las dependencias.

Antes de ofrecer una descarga binaria general, prepara la firma y notarización de distribución y valida la compilación resultante en el equipo destino. Los archivos `.pkg` deben ofrecerse como artefactos de una versión, separados del código fuente; no se incluyen en esta entrega.
