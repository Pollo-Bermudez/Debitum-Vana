# En tu nivel principal (Level_1.gd)
extends Node2D

# Variables del juego
var player_lives = 3
var player_coins = 0
var lives_label: Label
var coins_label: Label

func _ready():
	create_instant_hud()

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

# Llamar estas funciones cuando pase algo
func add_coin():
	player_coins += 1
	coins_label.text = "🪙 Blitzcoins: " + str(player_coins)

func lose_life():
	player_lives -= 1
	lives_label.text = "❤️ Vidas: " + str(player_lives)
 #   if player_lives <= 0:
 #       game_over()

#func game_over():
#    print("Game Over!")
