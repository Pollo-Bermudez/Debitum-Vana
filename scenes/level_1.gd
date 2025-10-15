# En tu nivel principal (Level_1.gd)
extends Node2D

# Variables del juego
var player_lives = 3
var player_coins = 0
var lives_label: Label
var coins_label: Label
var player: Node2D  # Referencia al jugador
var death_y_limit = 1200  # Coordenada Y límite para morir (ajústala según tu nivel)

func _ready():
	create_instant_hud()
	
	# Buscar el nodo del jugador en la escena
	player = get_node_or_null("Player") # asegúrate de que el nodo del jugador se llame "Player"
	if player == null:
		push_warning("⚠️ No se encontró el nodo del jugador. Verifica el nombre en el árbol de la escena.")

func _process(delta):
	if player:
		check_player_fall()

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
	# Reinicia al jugador en un punto seguro
	if player:
		player.global_position = Vector2(500, 500)  # Ajusta la posición inicial
		print("☠️ El jugador cayó y perdió una vida")

#func game_over():
#	print("💀 Game Over!")
#	get_tree().change_scene_to_file("res://Scenes/GameOver.tscn") # o puedes mostrar un menú
