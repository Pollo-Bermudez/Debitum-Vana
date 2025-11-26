extends Node2D

@export var game_over_scene : PackedScene
@export var pixel_font : Font

var lives_label: Label
var coins_label: Label
var player : Node2D = null
var death_y_limit = 1200
var spawn_position: Vector2 = Vector2(0, 0)

func _ready():
	create_instant_hud()
	
	
	player = get_node_or_null("Player")
	if player:
		spawn_position = player.global_position	
	
	# Si tienes monedas visuales animadas
	if has_node("Coin"): $Coin/AnimatedSprite2D.play("Girando")
	if has_node("Coin2"): $Coin2/AnimatedSprite2D.play("Girando")
	if has_node("Coin3"): $Coin3/AnimatedSprite2D.play("Girando")

func _process(delta):
	if player:
		check_player_fall()
	if Input.is_action_just_pressed("esc"):
		_on_button_pressed()

func check_player_fall():
	if player.global_position.y > death_y_limit:
		lose_life()
		respawn_player()

func lose_life():
	# AQUÍ USAMOS LA VARIABLE GLOBAL
	Global.vidas -= 1
	update_hud_text() 
	
	if Global.vidas <= 0:
		if player and player.has_method("initiate_death"):
			player.initiate_death()
		else:
			handle_player_death_cleanup()

func add_life(amount: int = 1):
	Global.vidas += amount
	update_hud_text()

func add_coin():
	# AQUÍ USAMOS LA VARIABLE GLOBAL
	Global.monedas += 1
	update_hud_text()

func create_instant_hud():
	var hud = CanvasLayer.new()
	add_child(hud)
	
	lives_label = Label.new()
	lives_label.position = Vector2(20, 20)
	if pixel_font: lives_label.add_theme_font_override("font", pixel_font)
	lives_label.add_theme_font_size_override("font_size", 16)
	hud.add_child(lives_label)
	
	coins_label = Label.new()
	coins_label.position = Vector2(20, 50)
	if pixel_font: coins_label.add_theme_font_override("font", pixel_font)
	coins_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(coins_label)
	
	update_hud_text() # Muestra los datos que traemos del nivel anterior

func update_hud_text():
	# LEEMOS DEL GLOBAL PARA MOSTRAR EN PANTALLA
	if lives_label: lives_label.text = "❤️ Vidas: " + str(Global.vidas)
	if coins_label: coins_label.text = "🪙 " + str(Global.monedas)

func respawn_player():
	if is_instance_valid(player):
		player.global_position = spawn_position

func handle_player_death_cleanup():
	game_over()

func game_over():
	# IMPORTANTE: Si muere definitivamente, reiniciamos los datos globales
	Global.reset_datos()
	
	if game_over_scene:
		get_tree().change_scene_to_packed(game_over_scene)

# --- MENÚ DE PAUSA (Igual que antes) ---
func _on_button_pressed() -> void:
	if has_node("CanvasLayer2"):
		$CanvasLayer2.visible = true
		if has_node("CanvasLayer"): $CanvasLayer.visible = false
		get_tree().paused = !get_tree().paused

func _on_button_2_pressed() -> void:
	# Al salir al menú principal, tal vez quieras resetear los datos o guardarlos
	Global.reset_datos() 
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu_inicial/menu.tscn")

func _on_button_3_pressed() -> void:
	if has_node("CanvasLayer2"): $CanvasLayer2.visible = false
	if has_node("CanvasLayer"): $CanvasLayer.visible = true
	get_tree().paused = false
