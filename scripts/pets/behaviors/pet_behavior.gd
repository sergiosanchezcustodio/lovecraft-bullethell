class_name PetBehavior
extends RefCounted
## Lo que hace un compañero además de seguir a su jugador (D-36). `Pet` calcula en cada paso
## el sitio donde se pondría (`pet.goal`) y su velocidad (`pet.speed`); el comportamiento
## puede cambiarlos para ir a por algo, y llama a `pet.act()` al atacar (animación de ataque).

var pet: Pet

static func make(kind: int) -> PetBehavior:
	match kind:
		PetData.Kind.BITE, PetData.Kind.CLAW, PetData.Kind.POISON: return PetHunt.new()
		PetData.Kind.DIVE: return PetDive.new()
		PetData.Kind.FETCH: return PetFetch.new()
		PetData.Kind.CONFUSE: return PetConfuse.new()
		PetData.Kind.HEAL: return PetHeal.new()
		PetData.Kind.ZAP: return PetZap.new()
		PetData.Kind.BLINK: return PetBlink.new()
		PetData.Kind.CHARGE: return PetCharge.new()
		PetData.Kind.BURROW: return PetBurrow.new()
		PetData.Kind.SPIT: return PetSpit.new()
		PetData.Kind.INSIGHT: return PetInsight.new()
		PetData.Kind.FORAGE: return PetForage.new()
		PetData.Kind.DEVOUR: return PetDevour.new()
	return PetBehavior.new()

func start() -> void:
	pass

func step(_delta: float) -> void:
	pass

## Su jugador ha subido de nivel (efectos pasivos).
func leveled() -> void:
	pass
