class_name BulletPattern
extends Resource
## Patrón de disparo enemigo, reutilizable entre enemigos (datos en data/patterns/).
## El estilo visual sale del daño: físico, mental o mixto.

enum Shape { RADIAL, FAN }

@export var id := &"radial"
@export var shape := Shape.RADIAL
@export var count := 12                  ## balas por ráfaga
@export var spread_deg := 60.0           ## abertura del abanico (solo FAN)
@export var speed := 5.0                 ## m/s
@export var radius := 0.13               ## colisión (m)
@export var size := 0.26                 ## radio visual (m)
@export var damage_physical := 8.0
@export var damage_mental := 0.0
@export var lifetime := 6.0
@export var bursts := 1
@export var burst_interval := 0.15
@export var spin_deg := 0.0              ## giro entre ráfagas (espirales)
@export var aimed := true                ## centrado hacia el objetivo
@export var gap_count := 0               ## huecos en un patrón radial (para atravesarlo)
@export var gap_width := 2               ## balas que faltan en cada hueco
@export var telegraph_time := 0.0        ## aviso previo en el suelo (s); 0 = sin aviso
@export var telegraph_radius := 1.2

func damage() -> Damage:
	return Damage.new(damage_physical, damage_mental)

func style() -> BulletManager.Style:
	match damage().kind():
		Damage.Kind.MENTAL: return BulletManager.Style.MENTAL
		Damage.Kind.MIXED: return BulletManager.Style.MIXED
	return BulletManager.Style.PHYSICAL

## Direcciones (plano XZ, unitarias) de una ráfaga, dado hacia dónde se apunta.
func directions(aim: Vector3, burst: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var base := atan2(aim.x, aim.z) if aimed and aim.length() > 0.001 else 0.0
	base += deg_to_rad(spin_deg) * burst
	for k in count:
		var a: float
		if shape == Shape.FAN:
			var spread := deg_to_rad(spread_deg)
			a = base + (0.0 if count == 1 else lerpf(-spread * 0.5, spread * 0.5, k / float(count - 1)))
		else:
			a = base + TAU * k / count
			if gap_count > 0 and (k % maxi(count / gap_count, 1)) < gap_width: continue
		out.append(Vector3(sin(a), 0, cos(a)))
	return out
