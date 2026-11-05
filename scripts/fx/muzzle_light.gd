class_name MuzzleLight
extends OmniLight3D
## Fogonazo de los disparos (hito 17.19): una luz cálida y corta en la mano del investigador que
## se enciende un instante con cada disparo de balas y alumbra el suelo y las paredes de al lado.
## Una por jugador, sin sombras; solo en Alta y Ultra (`shot_light` en data/quality.json). Las
## explosiones ya tenían la suya (Explosion, con tope `lights`).

const PEAK := 1.8                               ## brillo del fogonazo
const FADE := 16.0                            ## 1/s: se apaga en unos 0,07 s
var _k := 0.0

static func attach(player: Node3D, weapons: WeaponSystem, force := false) -> MuzzleLight:
	if not force and not bool(Quality.value("shot_light", true)): return null
	var l := MuzzleLight.new()
	l.name = "MuzzleLight"
	l.position = Vector3(0.0, 1.0, 0.45)
	l.light_color = Color(1.0, 0.72, 0.38)
	l.light_energy = 0.0
	l.omni_range = 3.6
	l.omni_attenuation = 1.6
	l.shadow_enabled = false
	l.light_cull_mask = 0xFFFFF & ~Player.VIS_PLAYER   # el suelo, las paredes y las criaturas: no lava al que dispara
	l.visible = false
	l.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # cambia en _process
	player.add_child(l)
	weapons.fired.connect(l._on_fired)
	return l

func _on_fired(w: WeaponSystem.Weapon) -> void:
	if w.data.delivery != WeaponData.Delivery.BULLET: return
	_k = 1.0 if _k < 0.4 else minf(_k + 0.5, 1.0)                   # con ráfagas, no se apaga del todo
	visible = true

func _process(delta: float) -> void:
	if not visible: return
	_k = maxf(_k - FADE * delta * _k - delta * 2.0, 0.0)
	light_energy = PEAK * _k * (0.85 + 0.3 * randf())
	if _k <= 0.0: visible = false
