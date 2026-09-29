class_name CharacterData
extends Resource
## Perfil de un personaje jugable. Los valores se ajustan jugando; aquí solo datos.

@export var id := &"dyer"
@export var display_name := "William Dyer"
@export var model := "dyer"                  ## nombre en models/ (y su juego de animaciones)
@export_group("Presentación")
@export var role := "Geólogo de la Universidad de Miskatonic"   ## debajo del nombre, en la selección
@export_multiline var passive_text := ""     ## su rasgo, en una frase (selección y ficha)
@export var story := "En las montañas de la locura"               ## relato del que viene
@export var price := 0                       ## en la tienda; 0 = disponible desde el principio
@export_group("Rasgos")
## Cada personaje tiene un único rasgo (D-35); los demás campos se quedan en su valor neutro.
## Daño recibido de enemigos con estas etiquetas (EnemyData.tags): {"marina": 0.7} = 30 % menos.
@export var resist_tags := {}
## Daño hecho a enemigos con estas etiquetas: {"humana": 1.25} = 25 % más.
@export var bonus_tags := {}
@export var knockback_immune := false        ## Johansen (D-19: aún no hay empuje sobre los jugadores)
@export var dodge_length := 1.0              ## multiplica la duración del impulso y la invulnerabilidad del esquive
@export var arcane_cost_mult := 1.0          ## cordura que cuestan las armas arcanas (Varga: 0,5)
@export var xp_mult := 1.0                   ## experiencia por gema (Blake: 1,15)
@export var heal_on_level := 0.0             ## fracción de la vida máxima que recupera al subir de nivel (Whipple)
@export var revive_speed := 1.0              ## rapidez al reanimar a un compañero (Whipple; hito 2.6)
@export var calm_aura := 0.0                 ## cordura por segundo a sí mismo y a los compañeros a menos de CALM_RADIUS (Iwanicki)
@export var physical_resist := 1.0           ## multiplica el daño físico recibido (Elwood: 0,85)
@export var dodge_cooldown_mult := 1.0       ## multiplica la recarga del esquive (Elwood: 0,8)
@export var close_bonus := 0.0               ## daño extra a quemarropa: +close_bonus junto al enemigo, 0 al alcance máximo (Malone)
@export var explosion_radius_mult := 1.0     ## radio de las explosiones de sus lanzados (Dyer: 1,25)
@export var melee_mult := 1.0              ## daño de las armas cuerpo a cuerpo (Johansen: 1,25)
@export var in_shop := false                 ## se compra en la tienda (precio en el hito 2.9; mientras, disponible)
@export var order := 0                       ## orden en la selección de personaje
@export_group("Atributos")
## Reparto de 20 puntos entre tres atributos según su historia (D-27), p. ej.
## {"CUL": 8, "POD": 7, "CON": 5}. Los demás se quedan en 10. Ver Attributes.
@export var attr_bonus := {}
@export_group("Recursos (base: los atributos la escalan)")
@export var max_health := 100.0
@export var max_sanity := 100.0
@export_group("Movimiento")
@export var move_speed := 4.5                ## m/s
@export var turn_speed := 14.0               ## rapidez al girar el modelo hacia donde se mueve
@export_group("Esquive")
@export var dodge_speed := 12.0              ## m/s durante el impulso
@export var dodge_duration := 0.25           ## s de impulso
@export var dodge_iframes := 0.32            ## s de invulnerabilidad desde que empieza
@export var dodge_cooldown := 1.2            ## s desde que empieza hasta poder repetir
## Animación del esquive (la fija su estilo; ver DodgeStyle).
@export var dodge_anim := "slide"
## Estilo de esquive del personaje (data/dodges/). Si está, sus valores sustituyen a los
## de arriba al crear el jugador.
@export var dodge_style: DodgeStyle
@export_group("Otros")
@export var luck := 1.0                      ## suerte en las mejoras
@export var crisis_weights := {}             ## pesos propios de las crisis (vacío: los comunes)
@export var pickup_radius := 2.2             ## a qué distancia empiezan a volar las gemas hacia él
## Armas con las que empieza. El GDD da una por personaje; en la fase 1 Dyer empieza
## con la suya y el revólver, como pide la especificación del prototipo.
@export var starting_weapons: Array[StringName] = [&"dinamita"]
@export var collision_radius := 0.32         ## choque con el decorado
@export var hurt_radius := 0.25              ## radio de impacto de las balas: pequeño, como en todo bullet hell
@export var hit_iframes := 0.6               ## s de invulnerabilidad tras recibir un golpe
