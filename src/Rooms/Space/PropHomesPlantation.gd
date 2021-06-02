tool
extends Prop


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	if not Globals.has_done(Globals.GameState.GOT_HOME):
		yield(E.run([
			A.play('sfx_spaceship_transition', Vector2.ZERO),
			E.current_room.goto_planet(script_name)
		]), 'completed')
		E.goto_room('HomesPlantation')
	else:
		yield(E.run([
			'Pato: RoomSpace-Homesplantation-Pato-01'
		]), 'completed')


func on_look() -> void:
	pass


func on_item_used(_item: Item) -> void:
	pass
