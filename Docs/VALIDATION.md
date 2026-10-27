# Alcance de las pruebas

## Prueba física previa del proyecto

En un Mac Intel con macOS 15.8.1 y lector Alcor Micro AU9540 se comprobó la lectura de tres certificados DER del DNIe y dos objetos asociados a claves privadas. La extensión 1.0 (5) publicó dos claves compatibles con RSA-SHA256; tras introducir el usuario el PIN en el diálogo del sistema, Ivanti completó una conexión autorizada. No se publican los datos de la tarjeta, los perfiles ni los registros de esa sesión.

La interfaz 1.0.6 (6) incorpora el escudo azul, Ayuda, Acerca de y pantalla completa desactivada. El usuario confirmó que Launchpad mostraba el icono. Esa actualización conservó intacta la extensión que había superado la prueba física.

## Copia para publicación

Se eliminan los ajustes personales de Xcode y de firma. Los scripts construyen la app y su extensión desde código fuente, en lugar de reutilizar una app instalada. La compilación de comprobación y el instalador se generan fuera de la carpeta que se entrega para publicar; sus resultados se describen en `PUBLICATION.md`.

Una recompilación desde este repositorio, en otro entorno y con otra firma, necesita sus propias pruebas de lectura, publicación de claves y autenticación. No se afirma compatibilidad probada con Apple Silicon, otros lectores, otras tarjetas o todos los servidores Ivanti.

## Actualización 1.0.7

La app anfitriona 1.0.7 (7) y la extensión 1.0.7 (6) se han compilado desde esta copia y se ha verificado su firma estricta. La app está instalada en el equipo de desarrollo. Se han comprobado en la interfaz las pestañas nuevas, el rechazo de una dirección vacía y la exportación del helper de Safari: archivo ejecutable solo por su usuario y limitado al origen HTTPS, sin ruta ni parámetros.

Las pruebas automatizadas pasan: rechazo de PSS para las capacidades del controlador DNIe actual, relleno PSS de OpenSC con SHA-256/384/512 verificado por Security.framework usando una clave efímera, rechazo de un mensaje alterado, validación de direcciones y entrecomillado del script.

Tras reinsertar el DNIe, macOS publicó dos identidades y dos claves: PKCS#1 con SHA-256/384/512 disponible y PSS no disponible. Se corrigió la selección de la clave de la prueba local para consultar la etiqueta de SecItem en lugar de SecKeyCopyAttributes, sin recurrir a la clave de firma digital. La prueba local de autenticación RSA PKCS#1 con SHA-256 terminó correctamente: el usuario introdujo el PIN en el diálogo local, el DNIe generó la firma y Security.framework la verificó con la clave pública. No se guardaron el reto, la firma ni el PIN. No se ha validado una conexión nueva de Ivanti con esta versión. El diagnóstico anterior de Safari mostró un rechazo de RSA-PSS antes del PIN; no se considera corregido por esta actualización. Véase COMPATIBILITY.md.

La selección de la clave de autenticación tiene una prueba específica: acepta la etiqueta del proveedor CertAutenticacion y rechaza etiquetas de firma digital, FNMT y coincidencias parciales en el nombre del titular. El inventario vuelve a consultarse ante inserción o retirada de tokens, sin repetir una prueba de firma.
