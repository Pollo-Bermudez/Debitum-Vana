extends CharacterBody2D

@export var velocidad: float = 60.0
@export var rango_vision: float = 1000.0
@export var rango_ataque: float = 800.0
@export var dano: int = 1
@export var tiempo_entre_ataques: float = 1.5
@export var tiempo_patrol: float = 2.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var temporizador_ataque: Timer = $Timer
@onready var temporizador_patruya: Timer = $PatrolTimer
@onready var attack_area: Area2D = $AttackArea

var jugador: Node2D = null
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var direccion: int = 1
var puede_atacar: bool = true

func _ready():
	# Timers
	temporizador_ataque.wait_time = tiempo_entre_ataques
	temporizador_ataque.one_shot = true
	temporizador_ataque.timeout.connect(_on_temporizador_ataque_timeout)

	temporizador_patruya.wait_time = tiempo_patrol
	temporizador_patruya.one_shot = false
	temporizador_patruya.timeout.connect(_on_temporizador_patruya_timeout)
	temporizador_patruya.start()

	# Debug: asegúrate de que AttackArea existe
	if attack_area == null:
		push_error("No se encontró AttackArea. Crea un Area2D hijo llamado 'AttackArea' con CollisionShape2D.")
	else:
		# Opcional: desactivarlo hasta el momento del ataque (no necesario, pero más claro)
		attack_area.monitoring = true

func _physics_process(delta):
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")
		if jugador != null:
			print("Enemy: ¡Jugador encontrado y listo para perseguir!")
			
	# gravedad
	if not is_on_floor():
		velocity.y += gravedad * delta
	if jugador == null:
		patrullar()
		move_and_slide()
		return 
	# A partir de aquí, el 'jugador' está garantizado para no ser NULL.
	var distancia = global_position.distance_to(jugador.global_position)
	
	if distancia <= rango_vision and distancia > rango_ataque:
		# perseguir
		var dir = sign(jugador.global_position.x - global_position.x)
		velocity.x = dir * velocidad
		sprite.play("walk")
		sprite.flip_h = dir < 0
	elif distancia <= rango_ataque:
		# atacar (si puede)
		velocity.x = 0
		if puede_atacar:
			realizar_ataque()
		else:
			sprite.play("idle")
	else:
		# patrullar
		patrullar()
		move_and_slide()

func patrullar():
	velocity.x = direccion * velocidad
	sprite.play("walk")
	sprite.flip_h = direccion < 0

func realizar_ataque():
	print("⚔️⚔️⚔️ Enemy: FUNCIÓN DE ATAQUE INICIADA ⚔️⚔️⚔️")
	puede_atacar = false
	sprite.play("attack")
	velocity.x = 0
	temporizador_ataque.start()
	print("⚔️ Enemy: realizando ataque, buscando objetivos en AttackArea...")

	# Revisar cuerpos dentro del Area2D
	var bodies = attack_area.get_overlapping_bodies()
	for b in bodies:
		# Solo dañar si el cuerpo pertenece al grupo 'player'
		if b.is_in_group("player"):
			print("Enemy: encontró player -> llamando recibir_dano en: ", b)
			# Llamar al método en el player (si existe)
			if b.has_method("recibir_dano"):
				b.recibir_dano(dano)
			else:
				# Si el jugador no tiene recibir_dano, intentamos restar vida por otra vía (debug)
				print("⚠️ El nodo player no define 'recibir_dano'. Agrega la función al script del Player.")
	# Nota: si no hay cuerpos en el área, no hace daño.

func _on_temporizador_ataque_timeout():
	puede_atacar = true
	print("⏰ Enemy: ¡Timer de ataque terminado! Puede atacar de nuevo.")

func _on_temporizador_patruya_timeout():
	# Cambia dirección durante patrulla
	direccion *= -1

func _on_AttackArea_body_entered(body):
	if body.is_in_group("player"):
		print("💢 Player detectado dentro del área de ataque.")
