# En 'poeta.gd'
extends CharacterBody2D

@export var dialogo: Array[String] = ["Poeta: ¿Quién eres tú, viajero? ¿Otro fantasma perdido en la niebla?","Willy: Solo busco un millón de Blitzcoins.", "Poeta: (riendo con tristeza) Aquí solo encontrarás recuerdos. ¿Quieres uno?", "Willy: Mejor vamos cerrando el Papoi"]

# ¡RECUERDA ARRASTRAR 'flashback_papa.tscn' AQUÍ EN EL INSPECTOR!
@export var escena_video_flashback: PackedScene

var jugador_cerca = false
# Esta "bandera" evita que el diálogo se inicie dos veces
var video_iniciado = false

func _ready():
	$Area2D.monitoring = true

func _input(event):
	# Si no estamos cerca, o el diálogo está activo, O el video ya se lanzó, no hacer nada.
	if not jugador_cerca or DialogosUi.is_dialogo_activo() or video_iniciado:
		return

	if event.is_action_pressed("interact") and not event.is_echo():
		
		# Marcamos que el proceso del video ha comenzado
		video_iniciado = true
		
		# Conectamos la señal UNA SOLA VEZ
		DialogosUi.dialogo_terminado.connect(on_dialogo_del_poeta_terminado, CONNECT_ONE_SHOT)

		# Iniciamos el diálogo
		DialogosUi.iniciar(dialogo)
		
		# Consumimos el clic
		get_viewport().set_input_as_handled()

# Esta función se llama cuando 'DialogosUi' emite la señal
func on_dialogo_del_poeta_terminado():
	print("El diálogo del Poeta terminó. Lanzando video...")
	
	if not escena_video_flashback:
		print("¡ERROR! 'escena_video_flashback' NO ESTÁ ASIGNADA EN EL INSPECTOR.")
		video_iniciado = false # Reseteamos para poder intentarlo de nuevo
		return

	var video_instancia = escena_video_flashback.instantiate()
	
	# Nos conectamos a la señal de que el video FUE BORRADO
	# para que el poeta pueda volver a hablar.
	video_instancia.tree_exited.connect(on_video_terminado_y_borrado)
	
	# Añadimos la escena de video a la escena principal.
	# Como ahora es un CanvasLayer, se dibujará encima de todo.
	get_tree().current_scene.add_child.call_deferred(video_instancia)

# Esta función se llama cuando el video termina Y se borra
func on_video_terminado_y_borrado():
	print("DEBUG Poeta: El video terminó. El poeta vuelve a estar disponible.")
	video_iniciado = false
	# Si solo quieres que el video se vea UNA vez, borra el contenido
	# de esta función y deja 'video_iniciado' en 'true' para siempre.

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		jugador_cerca = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		jugador_cerca = false
