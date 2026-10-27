# Compatibilidad con aplicaciones

El puente publica identidades mediante CryptoTokenKit. Las aplicaciones que utilizan Security.framework pueden descubrirlas y solicitar operaciones sobre la tarjeta. Mostrar un certificado no garantiza que la firma requerida por un servidor sea compatible.

## Diagnóstico integrado

La pestaña «Compatibilidad» consulta únicamente las claves del proveedor del puente. Muestra los algoritmos PKCS#1 y RSA-PSS con SHA-256, SHA-384 y SHA-512 que macOS declara disponibles. Esa comprobación no solicita el PIN.

La prueba local firma un reto aleatorio con la clave de autenticación y verifica el resultado con la clave pública. Puede solicitar el PIN mediante el diálogo del sistema. No realiza trámites, no transmite el reto a un servidor ni guarda reto, firma o PIN. No se repite automáticamente. Si el algoritmo no está disponible, se detiene antes de firmar. No usa como alternativa la clave de firma de documentos.

## Safari y elección de identidad

DNIe y FNMT pueden coexistir. Safari puede recordar un certificado para un servidor concreto y evitar mostrar el selector en una sesión posterior. La herramienta exportable desde «Navegadores» actúa únicamente sobre la preferencia de identidad de Safari de ese origen HTTPS (servidor y puerto); conserva los certificados y las claves. No altera todos los sitios ni otros programas.

Introduce el servidor que realmente solicita el certificado: una web puede redirigir a una pasarela de autenticación distinta. La herramienta elimina ruta, parámetros y fragmento de la URL y no acepta credenciales en ella. Se guarda con permisos de usuario y se ejecuta manualmente. Tras restablecer la preferencia, cierra Safari y abre una sesión nueva. Una elección posterior puede volver a recordarse. La app no puede imponer que Safari muestre siempre el selector.

## Límite RSA-PSS conocido

Se observó en Safari una solicitud `RSA:message-PSS:SHA256` rechazada antes de pedir el PIN. El controlador OpenSC de DNIe incluido declara capacidades 0x1c0 (PKCS#1 v1.5 y HASH_NONE), sin RSA sin relleno ni PSS nativo. Que un servidor admita también PKCS#1 no garantiza que el navegador lo seleccione.

La versión 1.0.7 reconoce los algoritmos PSS y los habilita solo si OpenSC confirma que el controlador puede ejecutarlos. OpenSC puede preparar el relleno por software cuando una tarjeta permite RSA sin relleno. No se anuncia esa capacidad en el DNIe actual, no se fuerzan APDU no documentadas y no se reduce la seguridad TLS. Las pruebas con claves efímeras validan la implementación matemática, pero no acreditan soporte PSS de una tarjeta física.

Por tanto, el acceso de Safari que requiere PSS continúa pendiente de una solución válida en el controlador o de una opción compatible del servidor. La lectura de certificados y la autenticación PKCS#1 son funciones distintas.

## Otros navegadores y programas

Las aplicaciones deben utilizar las identidades de macOS y un algoritmo admitido. Los programas que solo trabajan con PKCS#11 requieren su propio módulo/configuración; el puente no los configura automáticamente. No se sustituyen certificados FNMT, no se exporta la clave privada del DNIe y no se modifican perfiles VPN ni la confianza del sistema.

Referencias: [activos de tarjetas inteligentes en CryptoTokenKit](https://developer.apple.com/documentation/cryptotokenkit/using-cryptographic-assets-stored-on-a-smart-card), [preferencias de identidad de Apple](https://support.apple.com/guide/keychain-access/create-an-identity-preference-kyca6343b6c9/mac), [manual de comandos DNIe 3.0](https://www.dnielectronico.es/PDFs/Manual_de_Comandos_para_Desarrolladores_102.pdf). La mención general a RSA sin relleno en documentación no proporciona por sí sola una secuencia de comandos de firma validada para este controlador.

## Resultado de la prueba local 1.0.7

En el equipo Intel de desarrollo, la app publicada detectó dos identidades y dos claves del proveedor. Tras introducir el usuario el PIN en el diálogo del sistema, la prueba con la clave de autenticación RSA PKCS#1/SHA-256 generó una firma en el DNIe y la verificó correctamente con Security.framework. No se transmitió a ningún servidor. El soporte RSA-PSS con este controlador continúa no disponible y el acceso de Safari descrito arriba sigue pendiente.
