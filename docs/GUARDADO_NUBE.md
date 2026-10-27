# Copia de las partidas en la nube

Guía para los jugadores (fase 10). Con una cuenta de GitHub (gratis), el juego guarda una copia de tus tres partidas y de tus controles en tu cuenta, para seguir jugando en otro PC donde lo dejaste. Las partidas se siguen guardando en tu PC como siempre: la nube es solo una copia. Sin conexión, o si nunca la conectas, el juego funciona igual.

## Conectar la cuenta

1. Menú principal → **Configuración** → pestaña **Nube** (LB/RB o Q/E) → **Conectar con GitHub**.
2. El juego enseña un código de 8 letras (como `WDJB-MJHT`), lo copia y abre `github.com/login/device` en el navegador. Si no se abre, ábrela tú: el botón **Abrir la página** lo intenta otra vez. También puedes abrirla en el móvil con el código QR que hay al lado de la dirección.
3. Entra en GitHub si hace falta, pega o escribe el código y pulsa **Authorize**. El juego solo pide permiso para los *gists*, nada más de tu cuenta.
4. En unos segundos el juego dice «Conectado» y sube tus partidas.

Hazlo en cada PC donde juegues, con la misma cuenta.

## Qué se sube y cuándo

- **Se suben** los tres huecos de partida y los controles reasignados. El vídeo, el audio y el resto de la configuración son de cada PC (resolución, monitor) y no viajan.
- **Al guardar** (al acabar un nivel, al comprar, al salir…) la partida se sube sola a los pocos segundos. Se puede apagar en la pestaña **Nube** («Subir cada partida al guardarla»); entonces se sincroniza al abrir la elección de partida o con **Sincronizar ahora**.
- **Al abrir la elección de partida** el juego mira la nube y baja lo que hayas jugado en otro PC. Cada hueco dice cómo está su copia: *al día*, *por subir*, *sin copia* o *ha cambiado aquí y en otro PC*.
- **Si borras un hueco**, también se borra en la nube. Un PC que todavía la tenga guardada la volverá a subir: borrar en un PC nunca borra nada en los demás.

## Si una partida ha cambiado en dos PC

Pasa si juegas en dos PC sin conexión (o con la subida apagada) y después los conectas, o si ya tenías una partida en un hueco de un PC antes de conectarlo. El juego enseña las dos lado a lado, con su fecha, el PC donde se guardó, el tiempo jugado, los niveles, el dinero, los objetos y los compañeros (en dorado, lo que una tiene de más que la otra). Elige con cuál te quedas. Con **B** o **Esc** lo dejas para luego; volverá a preguntar al abrir la elección de partida.

La que no eliges deja de usarse, pero el juego guarda una copia aparte en este PC, por si te equivocas: `slot_N.descartada_<fecha>.json`, en la carpeta de partidas (en Windows, `%APPDATA%\Godot\app_userdata\Lovecraft Bullet Hell\saves`). El juego no las lee. Para recuperar una, cierra el juego, cambia el nombre de `slot_N.json` (la que hay ahora, por si acaso) y renombra la copia a `slot_N.json`; al abrir la elección de partida, el juego enseñará el conflicto otra vez y podrás quedarte con la de **Este PC**, que es la que has recuperado.

## Dónde está la copia

En un *gist* secreto de tu cuenta de GitHub, llamado «Lovecraft Library: Surviving Cthulhu · partidas guardadas», con un fichero por hueco (`slot_1.json`…), `controles.json` y `meta.json`. Lo abres desde el juego con **Ver la copia en GitHub** (pestaña **Nube**), o en `gist.github.com` con tu cuenta. Ahí está también el historial de cada subida (*Revisions*).

- **Secreto** quiere decir que no aparece en tu perfil ni en las búsquedas, pero lo puede abrir quien tenga el enlace. Las partidas no llevan datos personales: solo tu progreso en el juego.
- Si lo borras en GitHub, el juego crea otro en la siguiente subida con lo que tengas en el PC.

## Desconectar

Pestaña **Nube** → **Desconectar este PC**. La copia se queda en GitHub y tus partidas, en el PC. Para quitarle el permiso al juego del todo: GitHub → *Settings* → *Applications* → *Authorized OAuth Apps* → el juego → *Revoke*.

El permiso de la cuenta se guarda en el PC, en el fichero `cloud.json` de la carpeta de datos del juego. Quien use tu PC con tu usuario podría usarlo para leer o cambiar tus gists: en un PC compartido, desconéctalo al terminar.

## Si algo falla

- **«Sin conexión con GitHub»**: no hay internet o GitHub no responde. Se juega igual y se intenta otra vez en el siguiente guardado.
- **«GitHub ya no reconoce la conexión de este PC»**: se revocó el permiso o caducó. Conecta otra vez.
- **«El código ha caducado»**: pasan unos 15 minutos sin escribirlo. Vuelve a pulsar **Conectar con GitHub**.
- **«GitHub pide esperar un poco»**: demasiadas peticiones seguidas. Espera unos minutos.

## Para el autor: registrar la aplicación

La conexión necesita una *OAuth App* del juego en GitHub (una sola vez, gratis):

1. GitHub → *Settings* → *Developer settings* → *OAuth Apps* → **New OAuth App**.
2. *Application name*: `Lovecraft Library: Surviving Cthulhu`. *Homepage URL*: la del repositorio o la de itch.io. *Authorization callback URL*: la misma (el flujo por dispositivo no la usa, pero el formulario la pide).
3. Créala y marca **Enable Device Flow**.
4. Copia el **Client ID** en `data/cloud.json` (`"client_id"`). Es público: puede ir en el repositorio. No hace falta ningún *client secret*.

Pruebas sin la aplicación: `godot --headless --path . -- cloud_check cloud_token=$(gh auth token) cloud_marker=lovecraft_prueba.json cloud_delete=true` (con un token de `gh` con permiso `gist`).
