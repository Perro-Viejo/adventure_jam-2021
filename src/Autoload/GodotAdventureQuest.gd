extends Node
# (E) El núcleo de Godot Adventure Quest

# warning-ignore-all:unused_signal
signal inline_dialog_requested(options)
signal text_speed_changed(idx)

export(Array, Resource) var rooms = []
export(Array, PackedScene) var characters = []
export(Array, String, FILE, "*.tscn") var inventory_items = []
export(Array, Resource) var dialog_trees = []
export var skip_cutscene_time := 0.2
export var text_speeds := [0.1, 0.01, 0.0]
export var text_speed_idx := 0 setget _set_text_speed_idx

var in_run := false
# Se usa para que no se pueda cambiar de escena si está se ha cargado por completo,
# esto es que ya ha ejecutado la lógica de Room.on_room_transition_finished
var in_room := false setget _set_in_room
var current_room: Room = null
var clicked: Node
var cutscene_skipped := false

onready var game_width := get_viewport().get_visible_rect().end.x
onready var game_height := get_viewport().get_visible_rect().end.y
onready var half_width := game_width / 2.0
onready var half_height := game_height / 2.0
onready var main_camera: Camera2D = find_node('MainCamera')
onready var _defaults := {
	camera_limits = {
		left = main_camera.limit_left,
		right = main_camera.limit_right,
		top = main_camera.limit_top,
		bottom = main_camera.limit_bottom
	}
}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func _ready() -> void:
	# TODO: Asignar habitaciones, personajes, ítems y árboles de conversación a
	# las respectivas interfaces
	for character_scene in characters:
		var character: Character = character_scene.instance()
		if character.is_player:
			C.player = character
		C.characters.append(character)
	
	set_process_input(false)
	
	if OS.has_feature('editor'):
		DebugOverlay.visible = true


func _process(_delta: float) -> void:
	if not Engine.editor_hint and is_instance_valid(C.camera_owner):
		main_camera.position = C.camera_owner.position


func _input(event: InputEvent) -> void:
	if event.is_action_released('skip'):
		cutscene_skipped = true
		$TransitionLayer.play_transition('pass_down_in', skip_cutscene_time)
		yield($TransitionLayer, 'transition_finished')
		G.emit_signal('continue_clicked')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func wait(time := 1.0, is_in_queue := true) -> void:
	if is_in_queue: yield()
	if cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	yield(get_tree().create_timer(time), 'timeout')


# Detiene una cadena de ejecución
func break_run() -> void:
	pass


func run(instructions: Array, show_gi := true) -> void:
	G.block()
	
	for idx in instructions.size():
		var instruction = instructions[idx]

		if instruction is String:
			var i := instruction as String
			
			# TODO: Mover esto a una función que se encargue de evaluar cadenas
			# de texto
			if i == '...':
				yield(wait(1.0, false), 'completed')
			else:
				var char_talk: int = i.find(':')
				if char_talk:
					var char_name: String = i.substr(0, char_talk)
					if not C.is_valid_character(char_name): continue
					var char_line: String = i.substr(char_talk + 1)
					yield(C.character_say(char_name, char_line, false), 'completed')
		elif instruction is GDScriptFunctionState and instruction.is_valid():
			instruction.resume()
			yield(instruction, 'completed')
	
	if not D.active and show_gi:
		G.done()


# Es como run, pero salta la secuencia de acciones si se presiona la acción 'skip'.
func run_cutscene(instructions: Array) -> void:
	set_process_input(true)
	yield(run(instructions), 'completed')
	set_process_input(false)
	
	if cutscene_skipped:
		$TransitionLayer.play_transition('pass_down_out', skip_cutscene_time)
		yield($TransitionLayer, 'transition_finished')

	cutscene_skipped = false


# Retorna la opción seleccionada en el diálogo creado en tiempo de ejecución.
# NOTA: El flujo del juego se pausa hasta que el jugador seleccione una opción.
func show_inline_dialog(opts: Array) -> String:
	emit_signal('inline_dialog_requested', opts)
	return yield(D, 'option_selected')


func goto_room(path := '') -> void:
# warning-ignore:return_value_discarded
	if not in_room: return
	self.in_room = false

	G.block()

	$TransitionLayer.play_transition('fade_in')
	yield($TransitionLayer, 'transition_finished')
	
	C.player.last_room = current_room.script_name
	
	Globals.rooms_states[current_room.script_name] = current_room.state
	
	# Sacar los personajes de la habitación para que no sean eliminados
	current_room.on_room_exited()
	
	# Reiniciar la configuración de la cámara
	main_camera.limit_left = _defaults.camera_limits.left
	main_camera.limit_right = _defaults.camera_limits.right
	main_camera.limit_top = _defaults.camera_limits.top
	main_camera.limit_bottom = _defaults.camera_limits.bottom
	
	for r in rooms:
		var room = r as GAQRoom
		if room.id.to_lower() == path.to_lower():
			get_tree().change_scene(room.path)
#			get_tree().change_scene_to(room.scene)
			return
	
	printerr('No se encontró la Room %s' % path)


func room_readied(room: Room) -> void:
	current_room = room
	
	if Globals.rooms_states.has(room.script_name):
		room.state = Globals.rooms_states[room.script_name]
	
	room.is_current = true
	room.visited_first_time = false
	if room.visited_times == 0:
		room.visited = true
		room.visited_first_time = true
	room.visited_times += 1
	
	# Agregar a la habitación los personajes que tiene configurados
	for c in room.characters:
		var chr: Character = C.get_character(c.script_name)
		if chr:
			chr.position = c.position
#			chr.walk_to_point += chr.position
			room.add_character(chr)
	if room.has_player:
		room.add_character(C.player)
	
	room.on_room_entered()

	$TransitionLayer.play_transition('fade_out')
	yield($TransitionLayer, 'transition_finished')
	yield(wait(0.3, false), 'completed')
	
	if not room.hide_gi:
		G.done()

	self.in_room = true

	# Esto también hace que la habitación empiece a escuchar eventos de Input
	room.on_room_transition_finished()



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _set_in_room(value: bool) -> void:
	in_room = value
	Cursor.toggle_visibility(in_room)


func _set_text_speed_idx(value: int) -> void:
	text_speed_idx = value
	emit_signal('text_speed_changed', text_speed_idx)
