tool
extends Room

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _init() -> void:
	state = {
		visited = self.visited,
		visited_first_time = self.visited_first_time,
		visited_times = self.visited_times,
		has_mask = true,
		has_dentures = false,
		has_coat = true,
		has_brooms = true,
		dj_uses_mask = true,
		vieja_sleeping = false,
	}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_room_entered() -> void:
	I.remove_item('Pato', false)
	I.remove_item('Lobo', false)
	A.play_music('mx_bar_01', false)
	A.play('bg_bar', Vector2.ZERO, false)
	
	if visited_first_time:
		C.player.global_position = $Points/Entrance.global_position
		C.player.face_left(false)
	elif C.player.last_room == 'Sea':
		C.player.global_position = $Points/Sink.global_position
	
	if not state.has_mask or state.dj_uses_mask:
		$Props/WolfMask.disable(false)
	if not state.has_dentures:
		$Props/GlassWithDentures.disable(false)
	if not state.has_coat:
		$Props/Coat.disable(false)
	if not state.has_brooms:
		$Props/Brooms.disable(false)

func on_room_exited() -> void:
	A.stop('bg_bar', 0, false)
	A.stop('mx_bar_01', 0, false)
	A.stop('mx_bar_02', 0, false)
	.on_room_exited()

func on_room_transition_finished() -> void:
	if visited_first_time:
		E.run_cutscene([
			G.display('Ella es Pato.'),
			'Pato: Esta fiesta está re-buena.',
			C.player.face_left(),
			'Pato: Además Lobo está aquí.',
			G.display('Está enamorada de Lobo.'),
			C.change_camera_owner(C.get_character('Lobo')),
			E.wait(2.0),
			C.change_camera_owner(C.player),
			G.display('Pero no se atreve a hablarle.'),
			C.player.face_right(),
			'Pato: Hoy es el día....',
			G.display('Puedes disfrazarla.'),
			G.display('O vivir sus ensoñaciones para que se llene de coraje.'),
			'Pato: ¡HOY LE HABLARÉ A LOBO!',
			G.display('Haz clic para interactuar con los objetos.'),
			G.display('Y clic derecho para examinarlos.'),
			G.display('El inventario y la barra de coraje están arriba a la izquierda.'),
			G.show_inventory(2.0),
		])
	elif C.player.last_room == 'Sea':
		Globals.courage += 25
		yield(I, 'courage_update_shown')
		E.run(['Pato: Siento que ora sí le voy a hablar'])
	elif Globals.has_done(Globals.GameState.GOT_HOME):
		Globals.courage += 25
		yield(I, 'courage_update_shown')
		E.run(['Pato: Que bonito sueño...'])


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
# TODO: Poner aquí los métodos privados
