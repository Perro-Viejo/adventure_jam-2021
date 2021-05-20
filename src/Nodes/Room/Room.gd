# TODO: Crear un icono para este tipo de nodos
tool
class_name Room
extends Node2D
# Nodo base para la creación de habitaciones dentro del juego.

export var script_name := ''
export(Array, Dictionary) var characters := [] setget _set_characters
export var has_player := true
export var hide_gi := false

var is_current := false setget _set_is_current
var visited := false
var visited_first_time := false
var visited_times := 0
var limit_left := 0.0
var limit_right := 0.0
var limit_top := 0.0
var limit_bottom := 0.0
var state := {} setget _set_state, _get_state

var _path := []

onready var _nav_path: Navigation2D = $WalkableAreas.get_child(0)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	set_process_unhandled_input(false)
	
	if limit_left != 0.0:
		E.main_camera.limit_left = limit_left
	if limit_right != 0.0:
		E.main_camera.limit_right = limit_right
	if limit_top != 0.0:
		E.main_camera.limit_top = limit_top
	if limit_bottom != 0.0:
		E.main_camera.limit_bottom = limit_bottom
	
	if not Engine.editor_hint and is_instance_valid(C.player):
		C.player.connect('started_walk_to', self, '_update_navigation_path')

		for c in $Characters.get_children():
			(c as Node2D).queue_free()

		E.room_readied(self)


func _process(delta):
	if Engine.editor_hint or not is_instance_valid(C.player):
		return
	
	for c in $Characters.get_children():
		character_moved(c as Character)
		
	if _path.empty(): return

	var walk_distance = C.player.walk_speed * delta
	_move_along_path(walk_distance)


func _unhandled_input(event):
	if not has_player: return
	if not event.is_action_pressed('interact'):
		if event.is_action_released('look'):
			if I.active: I.set_active_item()
		return

	C.player.walk(get_local_mouse_position(), false)


func _get_property_list():
	var properties = []
	properties.append({
		name = "Camera limits",
		type = TYPE_NIL,
		hint_string = "limit_",
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	properties.append({
		name = "limit_left",
		type = TYPE_REAL
	})
	properties.append({
		name = "limit_right",
		type = TYPE_REAL
	})
	properties.append({
		name = "limit_top",
		type = TYPE_REAL
	})
	properties.append({
		name = "limit_bottom",
		type = TYPE_REAL
	})
	return properties


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func get_walkable_area() -> Navigation2D:
	return $WalkableAreas.get_child(0) as Navigation2D


func character_moved(chr: Character) -> void:
	var y_pos := chr.global_position.y
	
	for p in $Props.get_children():
		_check_baseline(p, y_pos, 2)
	
	for c in $Characters.get_children():
		_check_baseline(c, y_pos)


# Aquí es donde se deben cargar los personajes de la habitación para que sean
# renderizados en el juego.
func on_room_entered() -> void:
	pass


func on_room_transition_finished() -> void:
	pass


# Este método es llamado por GodotAdventureQuest cuando se va a cambiar de
# habitación. Por defecto sólo remueve los nodos de los personajes para que no
# desaparezcan sus instancias globales.
func on_room_exited() -> void:
	set_process(false)
	for c in $Characters.get_children():
		$Characters.remove_child(c)


func add_character(chr: Character) -> void:
	$Characters.add_child(chr)


func remove_character(chr: Character) -> void:
	$Characters.remove_child(chr)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _move_along_path(distance):
	var last_point = C.player.position
	
	while _path.size():
		var distance_between_points = last_point.distance_to(_path[0])
		if distance <= distance_between_points:
			C.player.position = last_point.linear_interpolate(
				_path[0], distance / distance_between_points
			)

#			character_moved(C.player)

			return

		distance -= distance_between_points
		last_point = _path[0]
		_path.remove(0)

	C.player.position = last_point
	C.player.idle(false)
	C.emit_signal('character_move_ended', C.player)

#	set_process(false)


func _update_navigation_path(start_position, end_position):
	_path = _nav_path.get_simple_path(start_position, end_position, true)
	_path.remove(0)
	set_process(true)


func _set_characters(value: Array) -> void:
	characters = value
	for v in value.size():
		if not value[v]:
			characters[v] = {
				script_name = '',
				position = Vector2.ZERO
			}
			property_list_changed_notify()


func _check_baseline(nde: Node, chr_y_pos: float, z := 1) -> void:
	if not nde is Clickable: return
	var baseline: float = nde.to_global(Vector2.DOWN * nde.baseline).y
	nde.z_index = z if baseline > chr_y_pos else 0


func _set_is_current(value: bool) -> void:
	is_current = value
	set_process_unhandled_input(is_current)


func _set_state(stored_state: Dictionary) -> void:
	state = stored_state

	self.visited = stored_state.visited
	self.visited_first_time = stored_state.visited_first_time
	self.visited_times = stored_state.visited_times


# Retorna el estado de la habitación para que sea tenido en cuenta la próxima vez
# que se entre a la habitación
func _get_state() -> Dictionary:
	state.visited = self.visited
	state.visited_first_time = self.visited_first_time
	state.visited_times = self.visited_times

	return state
