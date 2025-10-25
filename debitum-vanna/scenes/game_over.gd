extends CanvasLayer

const LEVEL_SCENE_PATH = "res://scenes/level_1.tscn"
const MENU_SCENE_PATH = "res://menu_inicial/menu.tscn"

func _on_reiniciar_nivel_button_pressed():
	var error = get_tree().change_scene_to_file(LEVEL_SCENE_PATH)
	if error != OK:
		push_warning("Error al cargar la escena")

func _on_Volver_Menu_pressed():
	var error = get_tree().change_scene_to_file(MENU_SCENE_PATH)
	if error != OK:
		push_warning("Error al regresar al menu")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
