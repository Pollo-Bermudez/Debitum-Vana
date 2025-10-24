extends Area2D

@export var heal_amount: int = 1  # Cuántas vidas recupera el botiquín

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player": 
		var level = get_tree().current_scene  
		if level.has_method("add_life"):  # Comprueba que la escena tenga el método
			level.add_life(heal_amount)  # Llama a la función para curar al jugador
		queue_free()  # Destruye el botiquín (ya fue usado)
