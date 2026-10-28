# Prueba online por internet (cierre de la fase 9)

Lista para tu prueba real con otra persona (hito 9.6c). Es lo que falta para dar por buena la fase 9: «una parte completa jugada entre dos PCs por internet, mezclando jugadores locales y remotos, sin desincronizaciones visibles; desconexión y vuelta de un invitado entre niveles» (`docs/ROADMAP.md`).

## Antes

- [ ] Los dos con la **misma build** (la de `builds/windows/` o `builds/macos/`): comprobad que la versión de abajo a la derecha del menú principal es la misma (`v0.9.0`).
- [ ] Cada uno con su partida guardada (un hueco cualquiera). El avance de la campaña cuenta en la del anfitrión.
- [ ] Hablando por voz aparte (Discord, teléfono): es lo más cómodo para comentar lo que veis.
- [ ] Ten a mano `docs/JUGAR_ONLINE.md` por si el router no abre el puerto solo.

## Conexión

- [ ] Crea la sala. Apunta lo que dice debajo del código (UPnP): «Puerto 24680 abierto» o el motivo por el que no.
- [ ] Si no lo abre: puerto UDP 24680 a mano en el router y la IP pública, o una red virtual (Tailscale, ZeroTier, Radmin VPN).
- [ ] La otra persona entra con el código. Apunta el ping que ve cada uno en la sala (arriba a la derecha; en rojo y con «(lenta)» si pasa de 250 ms).
- [ ] Mezclad locales y remotos: al menos un PC con **dos jugadores** (dos mandos, o mando y teclado).

## Partida (una parte entera, mejor la 1)

Mirad en cada PC y apuntad cualquier cosa rara:
- [ ] Los enemigos se mueven igual en los dos (sin saltos ni enemigos fantasma que no hacen daño o que dañan sin tocar).
- [ ] Las balas enemigas: las que esquivas en tu pantalla no te dan.
- [ ] Gemas: lo que recoge uno desaparece para los dos; la experiencia sube a la vez.
- [ ] Subidas de nivel: se para en los dos PC, elige quien sube, y sigue.
- [ ] Pausa desde cada PC, y quitarla.
- [ ] Derribo y reanimación de un jugador del otro PC (la flecha late si no se ve).
- [ ] Jefe del final de la parte: sus ataques avisados se ven y dañan igual en los dos.
- [ ] Al acabar cada nivel, los dos ven la pantalla final a la vez y con las mismas bajas.

## Desconexión y vuelta

- [ ] A mitad de un nivel, el invitado cierra el juego (o quita el cable). El anfitrión ve «… se ha desconectado: lo lleva la máquina».
- [ ] El invitado vuelve a abrir el juego y entra con el mismo código: «De vuelta: entrarás al empezar el siguiente nivel».
- [ ] Al pasar de nivel, entra con su personaje, su nivel y sus armas.
- [ ] Al final, el anfitrión sale al menú: el invitado ve «El anfitrión ha cerrado la partida» y su dinero se ha guardado.

## Después

- [ ] Cada uno abre *Jugar online → Abrir la carpeta de registros de conexión* y me pasa los registros de la prueba (`python tools/marcas.py` los resume: cada marca con lo que pasaba alrededor y lo que se veía en cada PC; `python tools/marcas.py --juntar mio.log suyo.log` pone los dos PC en una sola lista por hora, con los relojes igualados por las marcas, y avisa de los registros que no acaban en «Fin de la sesión») (`red_<fecha>.log`) y, si hubo algún error, también `godot.log` (la carpeta de arriba).
- [ ] Cuando veáis algo raro, pulsad **F9** o mantened **LB+RB** en el mando (apunta una marca con el nivel y el minuto en los registros de todos los PC, sin parar la partida; comprobad que con el mando sale el aviso «Marca apuntada») y decid por voz qué era. Si no, la hora aproximada: el registro tiene la hora en cada línea, y cada 5 s el estado de la partida, el ping y lo que se manda.
