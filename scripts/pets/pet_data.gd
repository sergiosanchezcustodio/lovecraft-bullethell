class_name PetData
extends Resource
## Compañero (D-20, D-36): se elige en la selección de personaje, acompaña toda la partida y
## sube de nivel con el jugador. Se desbloquean en la tienda o con logros. Lo que hace sale
## de `kind` (un PetBehavior por tipo, en scripts/pets/behaviors/).

@export var id := &"perro"
@export var display_name := "Perro de trineo"
@export var story := "En las montañas de la locura"
@export_multiline var description := ""
@export var price := 0
@export var model := ""                      ## en models/ (vacío: sin modelo todavía)
## BITE: corre a morder a los enemigos cercanos (perro). CLAW: araña a los que se acercan y se
## enfada si hieren a su jugador (gato). SPIT: escupe baba venenosa (sapo). INSIGHT: más
## experiencia (búho). FORAGE: encuentra dólares y baúles (rata). DEVOUR: se come las balas
## enemigas (shoggoth bebé).
enum Kind { BITE, CLAW, SPIT, INSIGHT, FORAGE, DEVOUR }
@export var kind := Kind.BITE
## Ataque: daño por golpe (por segundo en las zonas), crecimiento por nivel del jugador y s
## entre ataques. La rata usa `attack_damage` como dólares por hallazgo.
@export var attack_damage := 9.0
@export var attack_per_level := 2.0
@export var attack_every := 0.8
@export var attack_range := 5.5              ## alcance desde su jugador (o desde él, si dispara)
## Efecto pasivo o de cantidad (búho: experiencia extra; shoggoth: balas por segundo; rata:
## probabilidad de baúl), con su crecimiento por nivel y su tope.
@export var bonus := 0.0
@export var bonus_per_level := 0.0
@export var bonus_max := 1.0
@export var fly_height := 0.0                ## m sobre el suelo (búho); 0 = por el suelo
@export var follow_gap := 1.6                ## distancia a la que sigue a su jugador

## Efecto pasivo o de cantidad para un nivel del jugador.
func bonus_at(level: int) -> float:
	return minf(bonus + bonus_per_level * (level - 1), bonus_max)

## Daño (o dólares) del ataque para un nivel del jugador.
func attack_at(level: int) -> float:
	return attack_damage + attack_per_level * (level - 1)
