extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("esc"):
		_on_button_pressed()



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
