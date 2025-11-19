extends Area2D

func _on_body_entered(body: Node2D) -> void:
	$AudioStreamPlayer2D.play()
	if body.name == "Player": 
		var level = get_tree().current_scene  # Obtiene la escena principal (donde está el HUD)
		if level.has_method("add_coin"):  
			level.add_coin()  # Suma la moneda al HUD
		print("💰 Moneda recogida. Total: ", level.player_coins)
		hide()
		set_deferred("monitoring", false)



func _on_audio_stream_player_2d_finished() -> void:
	queue_free() 
