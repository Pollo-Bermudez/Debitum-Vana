# FadeTransition.gd
extends Control

@onready var color_rect = $CanvasLayer/ColorRect

func _ready():
	# Asegura que al iniciar el juego, el fader esté transparente
	preload("res://pre-game/pre-game.tscn")
	color_rect.color = Color(0, 0, 0, 0)

# Esta es la función que llamarás desde tu menú
func fade_to_scene(scene_path: String, duration: float = 0.5):
	
	# Habilita el mouse para bloquear clics durante el fade
	color_rect.mouse_filter = MOUSE_FILTER_STOP
	
	# 1. Fade OUT (hacia negro)
	var tween_out = create_tween()
	tween_out.tween_property(color_rect, "color", Color(0, 0, 0, 1), duration)
	await tween_out.finished
	
	# 2. Cambiar la escena (mientras la pantalla está negra)
	get_tree().change_scene_to_file(scene_path)
	
	# 3. Fade IN (desde negro)
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "color", Color(0, 0, 0, 0), duration)
	await tween_in.finished
	
	# Deshabilita el mouse otra vez
	color_rect.mouse_filter = MOUSE_FILTER_IGNORE


# En el Inspector, define la ruta a la siguiente escena
@export var proxima_escena_path: String = "res://pre-game/pre-game.tscn"

# Esta es tu función del botón "Jugar"
func _on_button_pressed():
	fade_to_scene(proxima_escena_path)
