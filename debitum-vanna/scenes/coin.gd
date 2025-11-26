extends Area2D

func _on_body_entered(body: Node2D) -> void:
	$AudioStreamPlayer2D.play()
	if body.name == "Player": 
		var level = get_tree().current_scene
		
		if level.has_method("add_coin"):  
			level.add_coin() 
		print("💰 Moneda recogida. Total: ", Global.monedas)
		hide()
		set_deferred("monitoring", false)

func _on_audio_stream_player_2d_finished() -> void:
	queue_free()
