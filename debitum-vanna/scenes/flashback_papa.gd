# En 'flashback_papa.gd'
# ¡ASEGÚRATE DE QUE EXTIENDE CANVASLAYER!
extends CanvasLayer

# Asegúrate de que el nombre '$VideoStreamPlayer' es correcto
@onready var video_player = $VideoStreamPlayer

func _ready():
	print("--- PASO 1: 'FlashbackPapa' (CanvasLayer) iniciando. ---")

	if video_player == null:
		print("¡ERROR! No se encontró el nodo '$VideoStreamPlayer'. Revisa el nombre.")
		return
	
	# Asegúrate de que SÍ tienes un video cargado en el Inspector
	if not video_player.stream:
		print("¡ERROR! El VideoStreamPlayer no tiene ningún archivo de video en la propiedad 'Stream'.")
		queue_free() # Borramos la escena si no hay video
		return
		
	print("--- PASO 2: Nodo de video encontrado. Conectando señal 'finished'...")
	
	# Conectamos la señal 'finished' del PROPIO video
	video_player.finished.connect(on_video_terminado)
	
	# Mostramos y reproducimos el video
	video_player.show()
	video_player.play()
	
	print("--- PASO 3: Video reproduciéndose. ---")


# Esta función se llama cuando el VideoStreamPlayer termina
func on_video_terminado():
	print("--- ¡PASO 4: Video terminado! Destruyendo escena de flashback. ---")
	
	# Esta escena ya cumplió su propósito, la eliminamos.
	# Esto también emitirá la señal 'tree_exited' que el Poeta está escuchando.
	queue_free()
