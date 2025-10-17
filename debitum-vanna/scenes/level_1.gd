extends Node2D

# Variables del juego
var player_lives = 3
var player_coins = 0
var lives_label: Label
var coins_label: Label
var player: Node2D  
var death_y_limit = 1200 
var spawn_position: Vector2 = Vector2(0, 0)

func _ready():
	create_instant_hud()
	
	# Buscar el nodo del jugador en la escena
	player = get_node_or_null("Player") # asegúrate de que el nodo del jugador se llame "Player"
	if player == null:
		push_warning("⚠️ No se encontró el nodo del jugador. Verifica el nombre en el árbol de la escena.")
	else:
		# 🛑 1. Guardar la posición inicial del jugador (se ejecuta solo una vez)
		spawn_position = player.global_position	

func _process(delta):
	if player:
		check_player_fall()

func check_player_fall():
	# Si el jugador cae por debajo del límite del mapa
	if player.global_position.y > death_y_limit:
		lose_life()
		# 🛑 3. CORRECCIÓN: Llamamos respawn_player sin argumentos, como está definida abajo
		respawn_player()

func create_instant_hud():
	# CanvasLayer
	var hud = CanvasLayer.new()
	add_child(hud)
	
	# Vidas
	lives_label = Label.new()
	lives_label.position = Vector2(20, 20)
	lives_label.text = "❤️ Vidas: " + str(player_lives)
	lives_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(lives_label)
	
	# Monedas
	coins_label = Label.new()
	coins_label.position = Vector2(20, 50)
	coins_label.text = "🪙 Blitzcoins: " + str(player_coins)
	coins_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(coins_label)

func add_coin():
	player_coins += 1
	coins_label.text = "🪙 Blitzcoins: " + str(player_coins)

func lose_life():
	player_lives -= 1
	lives_label.text = "❤️ Vidas: " + str(player_lives)
	
	#if player_lives <= 0:
	#	game_over()

func respawn_player():
	# 🛑 2. USO DE SPAWN_POSITION: Reinicia al jugador en el punto de spawn guardado
	if player:
		player.global_position = spawn_position # <-- Usa la posición guardada
		print("☠️ El jugador regresó al spawn.")
		

func handle_player_damage():
	# 🛑 4. Lógica de daño: resta vida y llama a respawn_player
	lose_life()
	respawn_player() # <-- Llama a respawn sin el argumento 'false'
	print("🤕 El jugador recibió daño y regresó al spawn.")

#func game_over():
#	print("💀 Game Over!")
#	get_tree().change_scene_to_file("res://Scenes/GameOver.tscn") # o puedes mostrar un menú


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_area_2d_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
