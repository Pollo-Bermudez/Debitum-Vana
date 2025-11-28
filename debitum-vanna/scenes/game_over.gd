extends CanvasLayer

const MENU_SCENE_PATH = "res://menu_inicial/menu.tscn"

func _on_reiniciar_nivel_button_pressed():
	var nivel_a_cargar = ""
	if Global.nivel_actual_path != "":
		nivel_a_cargar = Global.nivel_actual_path
	else:
		nivel_a_cargar = "res://scenes/level_1.tscn" 
	var error = get_tree().change_scene_to_file(nivel_a_cargar)
	if error != OK:
		push_warning("Error al cargar la escena: " + nivel_a_cargar)

func _on_Volver_Menu_pressed():
	var error = get_tree().change_scene_to_file(MENU_SCENE_PATH)
	if error != OK:
		push_warning("Error al regresar al menu")

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	pass
