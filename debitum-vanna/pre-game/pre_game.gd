extends Control

@export var dialogo: Array[String] = ["Vaya, parece que solo me quedan 600 dolares", "Necesito pasar a la casa, si no, voy a perderlo TODO!!", "Que deberia hacer?"]
@export var dialogo2: Array[String] = ["Recorcholis, he perdido tio", "Eh???........Que pasa?"]
@export var i = 0

func _ready():
	$AudioStreamPlayer2D.play()
	await get_tree().create_timer(2).timeout
	DialogosUi.iniciar(dialogo)
	await get_tree().create_timer(1).timeout
	$Continue.visible = true
	



func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		i += 1
		if not DialogosUi.is_dialogo_activo():
			DialogosUi.iniciar(dialogo)
		_on_dialogo_avanzado(i)
	

# Esta función se llamará AUTOMÁTICAMENTE cada vez 
# que DialogosUi emita la señal (es decir, cada vez que cambie de línea).
func _on_dialogo_avanzado(index: int):
	
	# Aquí puedes comprobar en qué línea vas
	print("El diálogo está ahora en la línea: ", index)
	
	if index == 2:
		$Continue.visible = false
		$get.visible = true
		$pass.visible = true
	
	if index == 4:
		$Continue.visible = false
		DialogosUi.visible = false


func _on_continue_pressed() -> void:
	Input.action_press("interact")
	await get_tree().create_timer(.05).timeout
	Input.action_release("interact")
	


func _on_get_pressed() -> void:
	DialogosUi.visible = false
	$get.visible = false
	$pass.visible = false
	fade_in_sprite(1.5) # Aparecerá en 2 segundos
	await get_tree().create_timer(2).timeout
	DialogosUi.iniciar(dialogo2)
	DialogosUi.visible = true
	await get_tree().create_timer(1).timeout
	$Continue.visible = true


func _on_pass_pressed() -> void:
	DialogosUi.visible = false
	$get.visible = false
	$pass.visible = false
	await get_tree().create_timer(2).timeout
	DialogosUi.iniciar(dialogo2)
	DialogosUi.visible = true
	await get_tree().create_timer(1).timeout
	$Continue.visible = true


# Esta función hace la magia
func fade_in_sprite(duracion: float):
	# Crea una nueva animación "tween"
	var tween = create_tween()
	
	# Anima la propiedad "modulate" del sprite.
	# Queremos que cambie a Color(1, 1, 1, 1) -> (visible)
	# durante el tiempo de "duracion".
	tween.tween_property($"card-ext-6", "modulate", Color(1, 1, 1, 1), duracion)
	
