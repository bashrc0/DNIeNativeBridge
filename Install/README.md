# Instalación de una compilación propia

Esta carpeta contiene los scripts necesarios para crear un instalador; no contiene paquetes `.pkg` ni una copia de la app firmada por el autor.

Compila y empaqueta siguiendo `Docs/BUILD.md`. Antes de instalar, cierra DNIeNativeBridge y cualquier sesión que esté usando el DNIe. El instalador coloca la app en `/Applications`, verifica su firma y registra la extensión en la sesión del usuario conectado. Solo admite el disco de arranque y puede solicitar autorización de administrador. No cambia perfiles VPN ni instala Ivanti.

El registro se limita al identificador de DNIeNativeBridge. No desactiva proveedores de tarjetas de otros programas. Para evitar registros de desarrollo duplicados, conserva una sola copia de la app en uso y no ejecutes las copias de compilación mientras utilizas la instalada.

Tras instalar, abre la app, inserta el DNIe y pulsa «Comprobar identidades». El PIN solo se introduce en el diálogo local del sistema cuando la aplicación compatible solicita autenticar la clave. No habilites el inicio de sesión del Mac con tarjeta para esta prueba: el objetivo es usar el token en la sesión ya abierta.

La distribución general requiere preparar la firma y notarización apropiadas. El instalador generado localmente no debe presentarse como software notarizado si no se ha completado ese proceso.
