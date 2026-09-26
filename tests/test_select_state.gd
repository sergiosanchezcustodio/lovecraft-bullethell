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
