extends GutTest
## Selección de personaje: unirse, personajes únicos (D-23), bloqueados, compañero y atrás.

var st: SelectState

func _char(id: String, price: int = 0) -> CharacterData:
	var c := CharacterData.new()
	c.id = StringName(id)
	c.price = price
	return c

func before_each() -> void:
	var chars: Array[CharacterData] = [_char("dyer"), _char("olmstead"), _char("legrasse"), _char("johansen", 500)]
	var pet := PetData.new()
	st = SelectState.new().setup(chars, [], [pet] as Array[PetData])

func test_cada_dispositivo_ocupa_un_puesto() -> void:
	assert_eq(st.join(-1), 0)
	assert_eq(st.join(0), 1)
	assert_eq(st.join(-1), -1, "el teclado ya está dentro")
	assert_eq(st.seat_of(0), 1)
	assert_ne(st.seats[0].character, st.seats[1].character, "el segundo empieza en otro personaje")

func test_un_personaje_confirmado_no_lo_puede_coger_otro() -> void:
	st.join(-1)
	st.join(0)
	st.seats[1].character = st.seats[0].character          # los dos mirando al mismo
	assert_true(st.confirm(0))
	assert_ne(st.seats[1].character, st.seats[0].character, "el otro pasa al siguiente libre")
	assert_false(st.choices(1).has(st.seats[0].character))
	st.seats[1].character = st.seats[0].character
	assert_false(st.confirm(1), "no puede confirmarlo")

func test_uno_bloqueado_no_se_puede_confirmar() -> void:
	st.join(-1)
	st.seats[0].character = 3
	assert_true(st.is_locked(3))
	assert_false(st.confirm(0))
	st.unlocked_characters = ["johansen"]
	assert_true(st.confirm(0))

func test_pasos_compañero_listo_y_atras() -> void:
	st.join(-1)
	assert_true(st.confirm(0))
	assert_eq(st.seats[0].stage, SelectState.Stage.PET)
	st.move(0, 1)
	assert_eq(st.seats[0].pet, 1)
	assert_true(st.confirm(0))
	assert_true(st.all_ready())
	assert_true(st.back(0))
	assert_false(st.all_ready())
	st.back(0)
	assert_false(st.back(0), "desde el personaje, atrás deja el puesto libre")
	assert_eq(st.joined().size(), 0)

func test_todos_listos_solo_si_todos_los_presentes_lo_estan() -> void:
	st.join(-1); st.join(0)
	st.confirm(0); st.confirm(0)
	assert_false(st.all_ready())
	st.confirm(1); st.confirm(1)
	assert_true(st.all_ready())
	st.unready_all()
	assert_false(st.all_ready())

## Vestuario (D-34): paso entre personaje y compañero si hay prendas; se salta si no.
func test_vestuario_solo_si_hay_prendas() -> void:
	st.join(-1)
	assert_true(st.confirm(0))
	assert_eq(st.seats[0].stage, SelectState.Stage.PET, "sin prendas, directo al compañero")
	var hat := OutfitData.new(); hat.id = &"bombin"; hat.slot = OutfitData.Slot.HEAD
	var boots := OutfitData.new(); boots.id = &"botas_nieve"; boots.slot = OutfitData.Slot.FEET
	var chars: Array[CharacterData] = [_char("dyer")]
	var s2 := SelectState.new().setup(chars, [], [] as Array[PetData], [hat, boots], {"dyer": {"feet": "botas_nieve"}})
	s2.join(-1)
	assert_eq(s2.worn_of(0), {"feet": "botas_nieve"}, "mientras elige personaje, lo de la última vez")
	s2.confirm(0)
	assert_eq(s2.seats[0].stage, SelectState.Stage.OUTFIT)
	s2.move(0, 1)
	assert_eq(s2.seats[0].worn.get("head"), "bombin")
	s2.vert(0, 1); s2.move(0, 1)                         # cuerpo: no hay prendas, sigue lo suyo
	assert_false(s2.seats[0].worn.has("body"))
	s2.vert(0, 1); s2.move(0, 1)                         # pies: de botas a lo suyo
	assert_false(s2.seats[0].worn.has("feet"))
	assert_true(s2.confirm(0))
	assert_eq(s2.seats[0].stage, SelectState.Stage.PET)
	s2.back(0)
	assert_eq(s2.seats[0].stage, SelectState.Stage.OUTFIT, "atrás vuelve al vestuario")

# ---------------------------------------------------------------- en red (hito 9.2)

## Perfil de otro PC: johansen desbloqueado y un compañero.
func _guest_profile() -> SelectState.Profile:
	var pr := SelectState.Profile.new()
	pr.name = "Invitada"
	pr.unlocked = ["johansen"]
	pr.pets.append(load("res://data/pets/gato.tres"))
	return pr

func test_cada_pc_juega_con_sus_desbloqueos() -> void:
	st.add_profile(7, _guest_profile())
	st.join(-1)                                          # anfitrión
	assert_eq(st.join(-1, 7), 1, "el mismo dispositivo en otro PC es otro jugador")
	st.seats[0].character = 3
	st.seats[1].character = 3
	assert_true(st.is_locked(3, 0), "el anfitrión no tiene a johansen")
	assert_false(st.is_locked(3, 1), "la invitada sí")
	assert_false(st.confirm(0))
	assert_true(st.confirm(1))
	assert_eq(st.pets_of(1).size(), 2, "sus compañeros, no los del anfitrión")
	assert_eq(st.profile_of(1).name, "Invitada")

func test_un_personaje_confirmado_en_otro_pc_tampoco_se_puede_coger() -> void:
	st.add_profile(7, _guest_profile())
	st.join(-1); st.join(0, 7)
	st.seats[1].character = st.seats[0].character
	assert_true(st.confirm(0))
	st.seats[1].character = st.seats[0].character
	assert_false(st.can_confirm(1), "D-23 entre PCs")
	assert_false(st.confirm(1))

func test_si_se_va_un_pc_quedan_libres_sus_puestos() -> void:
	st.add_profile(7, _guest_profile())
	st.join(-1); st.join(0, 7); st.join(1, 7)
	assert_eq(st.seats_of(7).size(), 2)
	st.remove_peer(7)
	assert_eq(st.joined(), [0] as Array[int])
	assert_false(st.profiles.has(7))

func test_acciones_y_lo_que_ve_cada_pc() -> void:
	st.add_profile(7, _guest_profile())
	assert_eq(st.act(7, 0, "confirm"), "", "confirmar sin puesto: se une")
	assert_eq(st.seat_of(0, 7), 0)
	assert_eq(st.act(7, 0, "up"), "cursor-1", "fuera del vestuario, arriba mueve la marca de la ficha")
	assert_eq(st.act(7, 0, "spin1"), "")
	assert_eq(st.seats[0].spin, 1)
	st.seats[0].character = 3
	assert_eq(st.act(1, -1, "join"), "")
	st.seats[1].character = 3
	assert_eq(st.act(1, -1, "confirm"), "shake", "el anfitrión no tiene a johansen")
	assert_eq(st.act(7, 0, "back"), "freed")
	assert_eq(st.act(7, 0, "back"), "exit", "sin puestos en su PC: salir")
	assert_eq(st.act(1, -1, "leave"), "")
	assert_true(st.joined().is_empty())

func test_el_estado_viaja_y_se_copia_igual() -> void:
	var guest := _guest_profile()
	guest.outfits = [OutfitData.find("bata")]
	st.add_profile(7, guest)
	st.join(-1); st.join(0, 7)
	st.seats[1].character = 3
	st.confirm(1)                                        # al vestuario (tiene una prenda)
	st.move(1, 1)                                        # cabeza: no hay; sigue lo suyo
	st.vert(1, 1); st.move(1, 1)                         # cuerpo: la bata
	st.confirm(1); st.move(1, 1)                         # el gato
	var copy := SelectState.new().setup(st.characters, [], [] as Array[PetData])
	copy.profiles_from_wire(bytes_to_var(var_to_bytes(st.profiles_to_wire())), DebugOptions.list_resources("res://data/pets"))
	copy.seats_from_wire(bytes_to_var(var_to_bytes(st.seats_to_wire())))
	assert_eq(copy.seats_to_wire(), st.seats_to_wire())
	assert_eq(copy.seats[1].worn, {"body": "bata"})
	assert_eq((copy.pets_of(1)[copy.seats[1].pet] as PetData).id, &"gato")
	assert_true(copy.is_locked(3, 0))
	assert_false(copy.is_locked(3, 1))

func test_un_perfil_con_ids_que_no_existen_se_limpia() -> void:
	var pr := SelectState.Profile.from_wire({"name": "X", "unlocked": ["johansen", "cthulhu", 7],
		"pets": ["gato", "dragon"], "outfits": ["bata", "corona"], "worn": {"dyer": {"body": "bata", "head": "bata"}}},
		DebugOptions.list_resources("res://data/pets"))
	assert_eq(pr.unlocked, ["johansen"])
	assert_eq(pr.pets.size(), 2, "ninguno y el gato")
	assert_eq(pr.outfits.size(), 1)
	assert_eq(pr.saved_worn, {"dyer": {"body": "bata"}}, "cada prenda solo en su hueco")
