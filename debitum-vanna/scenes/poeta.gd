extends CharacterBody2D

# Variable para guardar las líneas de diálogo de este NPC.
# Puedes hacerlo más complejo con nombres, retratos, etc.
@export var dialogo: Array[String] = ["Poeta: ¿Quién eres tú, viajero? ¿Otro fantasma perdido en la niebla?","Willy: Solo busco un millón de Blitzcoins.", "Poeta: (riendo con tristeza) Aquí solo encontrarás recuerdos. ¿Quieres uno?", "Willy: Mejor vamos cerrando el Papoi"]


# Esta variable está perfecta
var jugador_cerca = false

func _ready():
	# Esto está perfecto
	$Area2D.monitoring = true

# /////////////////////////////////////////////////
# /////NO USAR _process porque se bugea!!!!!!//////
# /////////////////////////////////////////////////
func _input(event):
	# Si el jugador no está cerca O el diálogo ya está activo,
	# no nos interesa este clic.
	if not jugador_cerca or DialogosUi.is_dialogo_activo():
		return

	if event.is_action_pressed("interact") and not event.is_echo():
		# 1. Iniciamos nuestro diálogo
		DialogosUi.iniciar(dialogo)
		print("caca")
		# 2. Consumimos el clic
		get_viewport().set_input_as_handled()

func _on_area_2d_body_entered(body):
	# Verificamos si el cuerpo que entró es el jugador.
	if body.is_in_group("player"):
		jugador_cerca = true
		print("El jugador está cerca, puedes hablar.") # Para depurar

# Esta función se llama cuando un cuerpo sale del Area2D.
func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		jugador_cerca = false
		print("El jugador se ha ido.") # Para depurar
