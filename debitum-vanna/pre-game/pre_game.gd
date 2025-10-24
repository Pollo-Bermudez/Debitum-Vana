extends Control



@export var dialogo: Array[String] = ["Willy: Vaya, parece que solo me quedan 600 dolares", "Willy: Necesito pasar a la casa, si no, voy a perderlo TODO!!", "Willy: Que deberia hacer?"]
@export var dialogo2: Array[String] = ["Willy: Recorcholis, he perdido tio", "Crupier: Lo siento, señor… la suerte no está de su lado.", "Willy (golpeando la mesa): ¡Otra mano! Apuesto lo que me queda…
","Voz misteriosa: Willy, Willy… siempre pensando que puedes engañar a la banca. Nos debes un millón de Blitzcoins. Una semana. Ni un día más.", "Willy: Joder tio tengo que conseguir la pasta", "Willy: Eh???........Que pasa?"]
@export var i: int = 0
var is_active: bool = false

func _ready():
	$AudioStreamPlayer2D.play()
	await get_tree().create_timer(2).timeout
	DialogosUi.iniciar(dialogo)
	# await get_tree().create_timer(1).timeout
	$Continue.visible = true
	is_active = true


# /////////////////////////////////////////////////
# /////NO USAR _process porque se bugea!!!!!!//////
# /////////////////////////////////////////////////

# func _process(delta: float) -> void:
#	if not is_active:
#		return
#	
#	if Input.is_action_just_pressed("interact"):
#		i += 1
#		if not DialogosUi.is_dialogo_activo():
#			DialogosUi.iniciar(dialogo)
#		_on_dialogo_avanzado(i)


func _input(event):
	var escena_actual = get_tree().current_scene.scene_file_path
	
	# 2. Si NO estamos en la escena de la intro, no hagas NADA.
	if "res://pre-game/pre-game.tscn" not in escena_actual:
		return 

	# ---------------------------------------------------
	
	# 3. Si SÍ estamos en la intro, ejecuta la lógica de siempre:
	
	if not (event.is_action_pressed("interact") and not event.is_echo()) and not (event.is_action_pressed("reject") and not event.is_echo()):
		return
		
	if not DialogosUi.is_dialogo_activo():
		return # No consumas el clic si el diálogo está cerrado

	_on_continue_pressed()
	
	if is_inside_tree():
		get_viewport().set_input_as_handled()

# Esta función se llamará AUTOMÁTICAMENTE cada vez 
# que DialogosUi emita la señal (es decir, cada vez que cambie de línea).
func _on_dialogo_avanzado(index: int):
	
	# Aquí puedes comprobar en qué línea vas
	print("El diálogo está ahora en la línea: ", index)
	
	if index == 2:
		$Continue.visible = false
		$get.visible = true
		$pass.visible = true
	
	if index == 3:
		if Input.is_action_just_pressed("interact"):
			#print('e')
			_on_get_pressed()
		if Input.is_action_just_pressed("reject"):
			#print('q')
			_on_pass_pressed()
	
	if index == 7:
		preload("res://scenes/level_1.tscn")
		#pass
	
	if index == 9:
		$Continue.visible = false
		#DialogosUi.visible = false
		# Esa puta linea de mierda me costo una hora y media de mi vida, la 
		# dejo como evidencia de por que luego no duermo
		is_active = false
		get_tree().change_scene_to_file("res://scenes/level_1.tscn")


func _on_continue_pressed() -> void:
	
	# 1. Hacemos lo que "dialogosui.gd" hace:
	if i != 9:
		DialogosUi.mostrar_siguiente_linea() 
	
	# 2. Hacemos lo que "pregame.gd" (este script) hace en _process:
	i += 1
	_on_dialogo_avanzado(i)


func _on_get_pressed() -> void:
	DialogosUi.visible = false
	$get.visible = false
	$pass.visible = false
	fade_in_sprite(1.5) # Aparecerá en 2 segundos
	await get_tree().create_timer(2).timeout
	DialogosUi.iniciar(dialogo2)
	DialogosUi.visible = true
	# await get_tree().create_timer(1).timeout
	$Continue.visible = true


func _on_pass_pressed() -> void:
	DialogosUi.visible = false
	$get.visible = false
	$pass.visible = false
	await get_tree().create_timer(1).timeout
	DialogosUi.iniciar(dialogo2)
	DialogosUi.visible = true
	# await get_tree().create_timer(1).timeout
	$Continue.visible = true


# Esta función hace la magia
func fade_in_sprite(duracion: float):
	# Crea una nueva animación "tween"
	var tween = create_tween()
	
	# Anima la propiedad "modulate" del sprite.
	# Queremos que cambie a Color(1, 1, 1, 1) -> (visible)
	# durante el tiempo de "duracion".
	tween.tween_property($"card-ext-6", "modulate", Color(1, 1, 1, 1), duracion)
	
