extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":  
		var level = get_tree().current_scene  # Obtiene la escena principal (donde está el HUD)
		if level.has_method("add_coin"):  
			level.add_coin()  # Suma la moneda al HUD
		queue_free()  
		print("💰 Moneda recogida. Total: ", level.player_coins)
