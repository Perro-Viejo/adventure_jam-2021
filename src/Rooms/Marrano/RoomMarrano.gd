tool
extends Room


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _init() -> void:
	state = {
		visited = self.visited,
		visited_first_time = self.visited_first_time,
		visited_times = self.visited_times,
		last_player_pos = Vector2.ZERO,
		container_weakness_revealed = false
	}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_room_entered() -> void:
	if not Globals.has_done(Globals.GameState.GARBAGE_THROWN):
		A.play('sfx_dome', $Props/Container.global_position, false)
	
	if visited_first_time:
		C.player.global_position = $Points/EntryPoint.global_position
		C.player.face_right(false)
		I.add_item('Pato', false)
		I.add_item('Lobo', false)
	else:
		C.player.global_position = state.last_player_pos

	A.play('bg_marrano', Vector2.ZERO, false)
	C.player.enable(false)
	C.get_character('Lobo').disable(false)
	
	# Verificar el estado de la habitación
	if state.container_weakness_revealed:
		get_prop('Container').description = 'Light-vault-3000X'


func on_room_transition_finished() -> void:
	if not Globals.has_done(Globals.GameState.CHARACTER_CHANGE_EXPLAINED):
		yield(Globals.explain_character_change(), 'completed')
	
	if visited_first_time:
		E.run([
			G.display('Pato saw the water Pig was guarding.'),
			C.player.face_up_right(),
			'Pato: We need that water to water our house-seed.'
		])
	elif Globals.has_done(Globals.GameState.GARBAGE_THROWN):
		yield(E.run_cutscene([
			A.play('sfx_dome', $Props/Container.global_position),
			'Pato: I better hide.',
			C.player_walk_to(get_point('Middle')),
			_play_fall(),
			A.play('sfx_garbage_fall', Vector2.ZERO, true, true),
			A.play('sfx_alarm', Vector2.ZERO),
			A.stop('sfx_dome', 0),
			'Marrano: MY FLOWERS!',
			C.character_walk_to('Marrano', get_point('Container')),
			"Marrano: Where are you stupid flower thief?",
			C.player_walk_to(get_point('Water')),
			'Pato: lol... The only stupid here is him.'
		]), 'completed')


func on_room_exited() -> void:
	state.last_player_pos = C.player.global_position

	if not Globals.has_done(Globals.GameState.GARBAGE_THROWN):
		A.stop('sfx_dome', 0, false)
	else:
		A.stop('sfx_alarm', 0, false)

	A.stop('bg_marrano', 0, false)
	C.get_character('Lobo').enable(false)

	.on_room_exited()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _play_fall() -> void:
	yield()
	$Props/Head/AnimationPlayer.play('fall')
	yield(get_tree(), 'idle_frame')
