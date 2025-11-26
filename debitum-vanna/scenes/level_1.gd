extends Node2D

@export var game_over_scene : PackedScene
@export var pixel_font : Font

# --- VARIABLES ---
var lives_label: Label
var coins_label: Label
var player = Node2D
var death_y_limit = 1200
var spawn_position: Vector2 = Vector2(0, 0)

func _ready():
	# Animaciones de monedas (asegúrate de que existen en la escena)
	if has_node("Coin"): $Coin/AnimatedSprite2D.play("Girando")
	if has_node("Coin2"): $Coin2/AnimatedSprite2D.play("Girando")
	if has_node("Coin3"): $Coin3/AnimatedSprite2D.play("Girando")
	if has_node("Coin4"): $Coin4/AnimatedSprite2D.play("Girando")
	if has_node("Coin5"): $Coin5/AnimatedSprite2D.play("Girando")
	if has_node("Coin6"): $Coin6/AnimatedSprite2D.play("Girando")
	if has_node("Coin7"): $Coin7/AnimatedSprite2D.play("Girando")
	
	create_instant_hud()
	
	# Buscar el nodo del jugador en la escena
	player = get_node_or_null("Player")
	if player == null:
		push_warning("⚠️ No se encontró el nodo del jugador.")
	else:
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

# --- HUD y ACTUALIZACIÓN DE DATOS ---

func create_instant_hud():
	# CanvasLayer
	var hud = CanvasLayer.new()
	add_child(hud)
	
	# Vidas
	lives_label = Label.new()
	lives_label.position = Vector2(20, 20)
	if pixel_font:
		lives_label.add_theme_font_override("font", pixel_font)
	lives_label.add_theme_font_size_override("font_size", 16)
	hud.add_child(lives_label)
	
	# Monedas
	coins_label = Label.new()
	coins_label.position = Vector2(20, 50)
	if pixel_font:
		coins_label.add_theme_font_override("font", pixel_font)
	coins_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(coins_label)
	
	# Actualizar texto inicial con los datos Globales
	update_hud_text()

func update_hud_text():
	# Esta función actualiza las etiquetas leyendo del Global
	if lives_label:
		lives_label.text = "❤️ Vidas: " + str(Global.vidas)
	if coins_label:
		coins_label.text = "🪙 " + str(Global.monedas)

func add_coin():
	Global.monedas += 1
	update_hud_text() # Actualizamos pantalla

func lose_life():
	Global.vidas -= 1
	update_hud_text() # Actualizamos pantalla
	
	if Global.vidas <= 0:
		if player and is_instance_valid(player) and player.has_method("initiate_death"):
			player.initiate_death()
		else:
			game_over() # Si no tiene animación de muerte, Game Over directo

# Función para agregar vidas con el botiquin
func add_life(amount: int = 1):
	Global.vidas += amount
	update_hud_text()
	print("💊 Vida recuperada. Total de vidas:", Global.vidas)

func respawn_player():
	if player and is_instance_valid(player):
		player.global_position = spawn_position
		print("☠️ El jugador cayó y regresó al spawn.")

func handle_player_death_cleanup():
	game_over()

func game_over():
	print("Game Over! Cargando pantalla de opciones")
	Global.reset_datos() # Reiniciamos los datos globales al morir
	
	if game_over_scene:
		get_tree().change_scene_to_packed(game_over_scene)
	else:
		push_warning("La escena no se cargó en el nivel")

# --- ZONAS Y BOTONES ---

func _on_area_2d_body_entered(body: Node2D) -> void:
	pass 

func _on_area_2d_body_exited(body: Node2D) -> void:
	pass 

func _on_button_pressed() -> void: # Pausa
	$CanvasLayer2.visible = true
	$CanvasLayer.visible = false
	get_tree().paused = !get_tree().paused

func _on_button_2_pressed() -> void: # Salir al Menú
	Global.reset_datos() # Reseteamos datos al salir al menú principal
	get_tree().paused = !get_tree().paused
	get_tree().change_scene_to_file("res://menu_inicial/menu.tscn")

func _on_button_3_pressed() -> void: # Continuar
	$CanvasLayer2.visible = false
	$CanvasLayer.visible = true
	get_tree().paused = !get_tree().paused
