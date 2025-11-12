extends Node2D

@export var game_over_scene : PackedScene

@export var pixel_font : Font

# Variables del juego
var player_lives = 3
var player_coins = 0
var lives_label: Label
var coins_label: Label
var player = Node2D
var death_y_limit = 1200
var spawn_position: Vector2 = Vector2(0, 0)

func _ready():
	$Coin/AnimatedSprite2D.play("Girando")
	$Coin2/AnimatedSprite2D.play("Girando")
	$Coin3/AnimatedSprite2D.play("Girando")
	$Coin4/AnimatedSprite2D.play("Girando")
	$Coin5/AnimatedSprite2D.play("Girando")
	$Coin6/AnimatedSprite2D.play("Girando")
	$Coin7/AnimatedSprite2D.play("Girando")
	create_instant_hud()
	
	
	# Buscar el nodo del jugador en la escena
	player = get_node_or_null("Player")
	if player == null:
		push_warning("⚠️ No se encontró el nodo del jugador. Verifica el nombre en el árbol de la escena.")
	else:
		# 1. Guardar la posición inicial del jugador (se ejecuta solo una vez)
		spawn_position = player.global_position	

func _process(delta):
	if player:
		check_player_fall()
	if Input.is_action_just_pressed("esc"):
		_on_button_pressed()

func check_player_fall():
	# Si el jugador cae por debajo del límite del mapa
	if player.global_position.y > death_y_limit:
		lose_life()
		respawn_player()

func create_instant_hud():
	# CanvasLayer
	var hud = CanvasLayer.new()
	add_child(hud)
	
	# Vidas
	lives_label = Label.new()
	lives_label.position = Vector2(20, 20)
	lives_label.text = "❤️ Vidas: " + str(player_lives)
	
	# ⬇️ 2. ASIGNA LA FUENTE Y EL TAMAÑO
	if pixel_font:
		lives_label.add_theme_font_override("font", pixel_font)
	lives_label.add_theme_font_size_override("font_size", 16) # O el tamaño que se vea bien
	
	hud.add_child(lives_label)
	
	# Monedas
	coins_label = Label.new()
	coins_label.position = Vector2(20, 50)
	coins_label.text = "🪙 " + str(player_coins)
	
	# ⬇️ 3. ASIGNA LA FUENTE Y EL TAMAÑO TAMBIÉN AQUÍ
	if pixel_font:
		coins_label.add_theme_font_override("font", pixel_font)
	coins_label.add_theme_font_size_override("font_size", 20) # Usa el mismo tamaño
	
	hud.add_child(coins_label)

func add_coin():
	player_coins += 1
	coins_label.text = "🪙 " + str(player_coins)

func lose_life():
	player_lives -= 1
	lives_label.text = "❤️ Vidas: " + str(player_lives)
	
	if player_lives <= 0:
		if player and is_instance_valid(player) and player.has_method("initiate_death"):
			player.initiate_death()
#Función para agregar vidas con el botiquin
func add_life(amount: int = 1):
	player_lives += amount
	lives_label.text = "❤️ Vidas: " + str(player_lives)
	print("💊 Vida recuperada. Total de vidas:", player_lives)


func respawn_player():
	# USO CORRECTO DE SPAWN_POSITION: Esto solo se usa cuando el jugador cae (check_player_fall).
	if player and is_instance_valid(player):
		player.global_position = spawn_position # Usa la posición guardada
		print("☠️ El jugador cayó y regresó al spawn.")
		

func handle_player_death_cleanup():
	game_over()

func game_over():
	print("Game Over! Cargando pantalla de opciones")
	if game_over_scene:
		get_tree().change_scene_to_packed(game_over_scene)
	else:
		push_warning("La escena no se cargo en el nivel")


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_area_2d_body_exited(body: Node2D) -> void:
	pass # Replace with function body.


func _on_button_pressed() -> void:
	$CanvasLayer2.visible = true
	$CanvasLayer.visible = false
	get_tree().paused = !get_tree().paused
	


func _on_button_2_pressed() -> void:
	get_tree().paused = !get_tree().paused
	get_tree().change_scene_to_file("res://menu_inicial/menu.tscn")


func _on_button_3_pressed() -> void:
	$CanvasLayer2.visible = false
	$CanvasLayer.visible = true
	get_tree().paused = !get_tree().paused
