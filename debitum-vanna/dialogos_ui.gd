extends CanvasLayer

# Conecta los nodos de la escena al script
# (Puedes arrastrarlos desde el árbol de escenas a la variable)
@onready var texto_label = $Panel/RichTextLabel
@onready var caja_dialogo = $Panel

var lineas_dialogo: Array[String] = []
var linea_actual = 0

func _ready():
	# El diálogo debe empezar oculto
	caja_dialogo.hide()

func _input(event):
	# Si la caja es visible y presionamos "interactuar"...
	if caja_dialogo.visible and Input.is_action_pressed("interact"):
		mostrar_siguiente_linea()

# Función para que otros (como el NPC) puedan llamarla
func iniciar(lineas: Array[String]):
	if lineas.is_empty():
		return
		
	lineas_dialogo = lineas
	linea_actual = 0
	caja_dialogo.show()
	texto_label.text = lineas_dialogo[linea_actual]
	
	# Pausamos el juego (al jugador) para que no se mueva mientras lee
	# get_tree().paused = true 
	# (Descomenta la línea de arriba si quieres pausar el juego)

func mostrar_siguiente_linea():
	linea_actual += 1
	if linea_actual < lineas_dialogo.size():
		texto_label.text = lineas_dialogo[linea_actual]
	else:
		# Se acabaron las líneas, cerramos
		lineas_dialogo = []
		linea_actual = 0
		caja_dialogo.hide()
		# get_tree().paused = false # Reanudamos el juego

# Función para que el NPC sepa si ya estamos en un diálogo
func is_dialogo_activo():
	return caja_dialogo.visible
