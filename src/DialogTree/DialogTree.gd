tool
class_name DialogTree
extends Resource

export(Array, Resource) var options := [] setget _set_options
export var script_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func start() -> void:
	_show_options()
	yield(D, 'dialog_finished')
	disconnect_option_selection()


func option_selected(_opt: DialogOption) -> void:
	pass


func disconnect_option_selection() -> void:
	if D.is_connected('option_selected', self, 'option_selected'):
		D.disconnect('option_selected', self, 'option_selected')


func show_option(id: String, is_visible := true) -> void:
	for o in options:
		if (o as DialogOption).id == id:
			o.visible = is_visible
			break


func is_option_visible(id: String) -> bool:
	for o in options:
		if (o as DialogOption).id == id:
			return o.visible
	return false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_options() -> void:
	D.emit_signal('dialog_requested', options)
	if not D.is_connected('option_selected', self, 'option_selected'):
		D.connect('option_selected', self, 'option_selected')


func _set_options(value: Array) -> void:
	options = value
	for v in value.size():
		if not value[v]:
			var new_opt: DialogOption = DialogOption.new()
			var id := 'Opt%d' % options.size()
			new_opt.id = id
			new_opt.text = 'Opción %d' % options.size()
			options[v] = new_opt
			property_list_changed_notify()
