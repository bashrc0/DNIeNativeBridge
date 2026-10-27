# DNIeNativeBridge

**Software libre y gratuito (GPL-3.0-or-later), compatible con macOS Sequoia 15.5 o posterior en Mac Intel.**

Puente para utilizar el DNIe con CryptoTokenKit en macOS y autenticarte en aplicaciones compatibles, como Ivanti Secure Access. Proyecto comunitario de RPastor, desarrollado con asistencia de GPT y basado en los componentes abiertos reconocidos en [NOTICE.md](NOTICE.md).

Versión de la interfaz: **1.0.7 (7)**. Extensión: **1.0.7 (6)**. Incluye diagnóstico de compatibilidad, prueba local de firma y herramientas para elegir certificado en Safari, además del escudo azul, Ayuda, Acerca de y pantalla completa desactivada.

## Alcance y requisitos

- Mac Intel; macOS Sequoia 15.5 o posterior.
- Lector de tarjetas compatible y DNIe con sus certificados vigentes.
- Ivanti instalado y un perfil de conexión proporcionado por tu organización, si vas a utilizarlo.
- La prueba física realizada fue en macOS 15.8.1 con un lector Alcor Micro AU9540. Apple Silicon, otros lectores y otras configuraciones están pendientes de validación.

El puente usa el canal CWA 14890 y los objetos PKCS#15 del DNIe. La clave privada permanece en la tarjeta. El PIN se introduce en el diálogo local del sistema; la app no lo guarda y la extensión desactiva su caché. Este repositorio no incluye certificados personales, perfiles VPN, direcciones de portales corporativos ni registros de sesiones.

## Compilar

Consulta [Docs/BUILD.md](Docs/BUILD.md). La carpeta contiene el proyecto Xcode y un compilador por línea de comandos que construye la app **y** la extensión desde sus fuentes, sin copiar una app instalada ni utilizar una identidad de firma del autor.

```sh
python3 Scripts/build.py
```

Este comando genera una compilación con firma ad hoc para comprobar la construcción. Para utilizar el token, configura tu identidad de desarrollo de Apple; las instrucciones están en la guía. El proyecto Xcode no lleva un equipo de desarrollo asignado.

## Uso

1. Instala y registra una compilación firmada siguiendo [Install/README.md](Install/README.md).
2. Conecta el lector e introduce el DNIe.
3. Abre DNIeNativeBridge; «Actualizar» muestra el lector y «Comprobar identidades» consulta las claves publicadas por macOS.
4. Conecta desde tu aplicación compatible e introduce el PIN únicamente cuando lo solicite el sistema.
5. En «Compatibilidad», consulta los algoritmos publicados y, si lo necesitas, prueba una firma de autenticación local.
6. En «Navegadores», puedes guardar una herramienta que restablece únicamente la elección recordada de Safari para un servidor HTTPS. No borra certificados ni fuerza el uso del DNIe.

**Límite conocido:** Safari puede solicitar RSA-PSS. El controlador DNIe incluido solo declara PKCS#1 v1.5; esa combinación puede fallar antes de pedir el PIN. Esta versión no resuelve aún ese acceso ni garantiza compatibilidad universal. Véase [Docs/COMPATIBILITY.md](Docs/COMPATIBILITY.md).

«Leer certificados» es un diagnóstico opcional sin PIN. Consulta [Docs/VALIDATION.md](Docs/VALIDATION.md) para distinguir las pruebas físicas previas de las comprobaciones de esta copia para publicación.

## Dependencias y licencia

El código propio y las adaptaciones se ofrecen bajo **GPL-3.0-or-later**; se conservan los avisos y licencias de los componentes originales. Véanse [LICENSE](LICENSE), [NOTICE.md](NOTICE.md) y [ThirdParty/README.md](ThirdParty/README.md). Las bibliotecas estáticas necesarias están incluidas junto con sus fuentes y versiones; [Scripts/rebuild-dependencies.sh](Scripts/rebuild-dependencies.sh) describe su reconstrucción.

Este proyecto no es un producto oficial de Apple, Ivanti ni de la entidad emisora del DNIe. No se ha usado código de McDNIe.

## Autoría y contacto

Responsable del proyecto: **RPastor**. Desarrollo con asistencia de **GPT**. Consultas y sugerencias: [GitHub Issues](https://github.com/bashrc0/DNIeNativeBridge/issues). Los componentes originales mantienen su autoría y licencias.
