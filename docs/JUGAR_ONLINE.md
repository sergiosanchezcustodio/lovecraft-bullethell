# Jugar online

Guía para los jugadores (hito 9.6c). Hasta cuatro jugadores en total, repartidos entre uno y cuatro PC: por ejemplo, dos en el sofá de un PC y otros dos, cada uno en su casa. Un PC crea la sala (el **anfitrión**) y los demás se unen con un código (los **invitados**). Todos tienen que tener la misma versión del juego.

## Crear una sala (anfitrión)

1. Menú principal → **Jugar** → **Jugar online** → **Crear sala**.
2. La primera vez, Windows pregunta si deja que el juego use la red: acepta **en redes privadas y públicas**. Si dijiste que no, ve a *Seguridad de Windows → Firewall y protección de red → Permitir una aplicación a través del firewall* y marca el juego en las dos columnas.
3. Arriba a la izquierda aparece el **código de la sala** (8 letras, como `K7Q2-M9XA`). Con **Select** (mando) o **C** (teclado) se copia; pásaselo a los demás por mensaje.
   - Debajo pone si el router ha abierto el puerto solo (UPnP): «Puerto 24680 abierto». Entonces el código vale para cualquiera, esté donde esté.
   - Si pone «El router no responde a UPnP», «El router no deja abrir el puerto» o «El router no tiene IP pública», el código solo sirve **dentro de tu casa**. Mira «Si no se puede entrar desde fuera».
4. Elegid personajes. Cuando todos estén listos, el anfitrión elige el nivel en el mapa.

## Unirse a una sala (invitado)

1. Menú principal → **Jugar** → **Jugar online** → **Unirse a una sala**.
2. Escribe o pega el código (con el mando, elige las letras con el selector). También vale una IP, como `83.45.201.7`.
3. Ya en la sala, cada jugador de tu PC se une con **Start** (o **Intro**) y elige personaje y compañero con sus desbloqueos.

## Durante la partida

- **Cada PC tiene su cámara** y sigue a sus jugadores. Los de otros PC que no se ven tienen una **flecha** en el borde con su distancia; si están derribados, la flecha late: ¡id a levantarlos!
- En el panel de cada jugador de otro PC se ve su PC y su **ping**: verde (bien), amarillo (se nota algo) o rojo (más de 250 ms: el juego sigue, pero los enemigos se ven con algo de retraso).
- **Subidas de nivel y pausa paran la partida en todos los PC.** Quien sube elige en su pantalla; si tarda más de 30 s, el anfitrión puede elegir en su lugar.
- **Dinero, logros y estadísticas** se guardan en la partida de cada uno. **El avance de la campaña** (niveles superados) solo en la del anfitrión.

## Si alguien se desconecta

- **Se va un invitado:** sus jugadores los lleva la máquina hasta el final del nivel. Puede volver a entrar con el mismo código: espera en la sala («De vuelta: entrarás al empezar el siguiente nivel») y entra al pasar de nivel con su progreso.
- **El anfitrión deja de responder:** sale «Sin noticias del anfitrión… N s». Si vuelve, la partida sigue; a los 10 s aparece «Salir al menú principal».
- **El anfitrión cierra:** los invitados ven «El anfitrión ha cerrado la partida» (o «Se ha perdido la conexión») con lo conseguido. Lo ganado ya está guardado.

## Si no se puede entrar desde fuera

El juego usa el **puerto UDP 24680** (si está ocupado, el siguiente: 24681… hasta 24687; lo dice la sala).

1. **Abre el puerto a mano** en el router del anfitrión (suele estar en `192.168.1.1` o `192.168.0.1`, apartado *NAT*, *Redirección de puertos* o *Port forwarding*): protocolo **UDP**, puerto externo e interno **24680**, hacia la IP del PC del anfitrión en casa (la sala la enseña como «en casa: …» o mira `ipconfig` en Windows).
2. Busca la **IP pública** del anfitrión (por ejemplo, buscando «cuál es mi IP» en internet) y que los invitados la escriban en lugar del código: `83.45.201.7`.
3. Si aun así no entra, puede que el proveedor de internet no dé IP pública (CGNAT, habitual en fibra y móviles). Prueba a que haga de anfitrión otro jugador, o usad una red virtual como Tailscale, ZeroTier o Radmin VPN e introducid la IP que os dé (`100.x.x.x`, `25.x.x.x`…).

## Mensajes al entrar

| Mensaje | Qué pasa |
|---|---|
| «No responde nadie en esa dirección» | Código o IP mal escritos, el anfitrión ha cerrado la sala o el puerto no está abierto. |
| «Versión distinta del juego: actualizad los dos a la misma» | Uno tiene una versión más nueva. Si la diferencia es grande, puede que ni siquiera salga este mensaje: comprobad las versiones. |
| «La sala está llena» | Ya hay cuatro jugadores. |
| «La partida ya ha empezado: espera a que vuelvan a la sala» | Solo puede entrar con la partida empezada quien se fue de ella. |

## Registros de conexión

Cada partida online deja un registro en la carpeta de registros (botón **Abrir la carpeta de registros de conexión** en *Jugar online*; en Windows, `%APPDATA%\Godot\app_userdata\Lovecraft Bullet Hell\logs\red`). Si algo va mal, envía el de esa partida (el más reciente) y, si puedes, el `godot.log` de la carpeta de arriba. Los registros llevan las IP de la partida.

## Texto para itch.io

> **Cooperativo online (beta).** Hasta cuatro investigadores entre uno y cuatro PC, mezclando jugadores en el mismo sofá y a distancia. Uno crea la sala y comparte un código de 8 letras; el juego intenta abrir el puerto del router solo (UPnP) y, si no puede, basta con abrir el puerto UDP 24680. Cada uno conserva su dinero, logros y desbloqueos; si alguien se cae, la máquina lleva a su investigador hasta que vuelva.
