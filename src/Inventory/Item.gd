# warnings-disable
extends Control
class_name Item
# Estos son los objetos que podrán ir al inventario:
# GraphicInterfaceLayer > InventoryContainer > ... > InventoryGrid

signal description_toggled(description)
signal selected(item)

export var description := ''
export var stack := false
export var script_name := ''
export(Cursor.Type) var cursor

var amount := 1
var in_inventory := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	connect('mouse_entered', self, '_toggle_description', [true])
	connect('mouse_exited', self, '_toggle_description', [false])
	connect('gui_input', self, '_on_action_pressed')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
# Cuando se le hace clic en el inventario
func on_interact() -> void:
	emit_signal('selected', self)


# Lo que pasará cuando se haga clic derecho en el icono del inventario
func on_look() -> void:
	pass


# Lo que pasará cuando se use otro Item del inventario sobre este
func on_item_used(_item: Item) -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _toggle_description(display: bool) -> void:
	Cursor.set_cursor(cursor if display else null)
	G.show_info(description if display else '')
	emit_signal('description_toggled', description if display else '')


func _on_action_pressed(event: InputEvent) -> void: 
	var mouse_event := event as InputEventMouseButton 
	if mouse_event:
		if mouse_event.is_action_pressed('interact'):
			if I.active:
				on_item_used(I.active)
			else:
				on_interact()
		elif mouse_event.is_action_pressed('look'):
			pass
