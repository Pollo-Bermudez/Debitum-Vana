extends CharacterBody2D

# Variable para guardar las líneas de diálogo de este NPC.
# Puedes hacerlo más complejo con nombres, retratos, etc.
@export var dialogo: Array[String] = ["¿Quién eres tú, viajero? ¿Otro fantasma perdido en la niebla?", "Aquí solo encontrarás recuerdos. ¿Quieres uno?"]


# Esta variable está perfecta
var jugador_cerca = false

func _ready():
	# Esto está perfecto
	$Area2D.monitoring = true

func _process(delta):
	# --- CAMBIO 2: LA LÓGICA DE INTERACCIÓN ---
	if jugador_cerca and Input.is_action_just_pressed("interact"):
		
		# En lugar de emitir una señal, llamamos DIRECTAMENTE al Autoload "DialogoUI".
		# También añadimos una comprobación para no reiniciar el diálogo si ya está abierto.
		if not DialogosUi.is_dialogo_activo():
			DialogosUi.iniciar(dialogo)


# Esta función se llama cuando un cuerpo entra en el Area2D.
func _on_area_2d_body_entered(body):
	# Verificamos si el cuerpo que entró es el jugador.
	# Es una buena práctica agregar el jugador a un grupo llamado "player".
	if body.is_in_group("player"):
		jugador_cerca = true
		print("El jugador está cerca, puedes hablar.") # Para depurar

# Esta función se llama cuando un cuerpo sale del Area2D.
func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		jugador_cerca = false
		print("El jugador se ha ido.") # Para depurar
