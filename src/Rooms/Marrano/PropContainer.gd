tool
extends Prop


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	if not Globals.has_done(Globals.GameState.DOME_SPOTTED):
		yield(
			E.run([
				C.walk_to_clicked(),
				'Pato: Can de mis amores, abrase el shut aquí',
				'Lobo: =O ¿Vámos a delinquír?',
				'Pato: Pero solo un poquito...'
			]), 'completed'
		)
		E.goto_room('Spaceship')
		Globals.did(Globals.GameState.DOME_SPOTTED)
	else:
		E.run([
			'Pato: ¡No hay tiempo que perder, a por el agua!'
		])

func on_look() -> void:
	pass


func on_item_used(item: Item) -> void:
	pass
