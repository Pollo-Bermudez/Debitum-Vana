extends CharacterBody2D

@export var velocidad: float = 60.0
@export var rango_vision: float = 100.0
@export var rango_ataque: float = 80.0
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

	# Conectar señal para detectar colisión inmediata
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)

func _physics_process(delta):
	# 1. BÚSQUEDA DEL JUGADOR
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")
		if jugador != null:
			print("Enemy: ¡Jugador encontrado y listo para perseguir!")
			
	# 2. GRAVEDAD
	if not is_on_floor():
		velocity.y += gravedad * delta
	
	velocity.x = 0
		
	# Si no se encuentra el jugador, patrullar.
	if jugador == null:
		patrullar()
	else:
		# 3. LÓGICA DE COMPORTAMIENTO
		var distancia = global_position.distance_to(jugador.global_position)
		
		if distancia <= rango_vision:
			# 🆕 SIEMPRE MOVERSE HACIA EL JUGADOR (perseguir o atacar)
			var dir = sign(jugador.global_position.x - global_position.x)
			velocity.x = dir * velocidad
			sprite.flip_h = dir < 0
			
			# Reproducir animación de caminar (el daño se aplica por colisión, no por animación)
			sprite.play("walk")
		else:
			# PATRULLAR
			patrullar()
	
	# 4. APLICAR MOVIMIENTO
	move_and_slide()

func patrullar():
	velocity.x = direccion * velocidad
	sprite.play("walk")
	sprite.flip_h = direccion < 0

# 🆕 ESTA ES LA FUNCIÓN CLAVE - Se ejecuta automáticamente cuando el jugador entra al área
func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and puede_atacar:
		print("💥 Enemy: ¡CONTACTO CON JUGADOR! Aplicando daño inmediato")
		
		# Marcar cooldown
		puede_atacar = false
		temporizador_ataque.start()
		
		# Aplicar daño INMEDIATAMENTE
		var level = get_tree().current_scene
		if level.has_method("handle_player_damage"):
			level.handle_player_damage()
			print("✅ Player recibió daño y fue enviado al spawn")

func _on_temporizador_ataque_timeout():
	puede_atacar = true
	print("⏰ Enemy: ¡Timer de ataque terminado! Puede atacar de nuevo.")

func _on_temporizador_patruya_timeout():
	# Cambia dirección durante patrulla
	direccion *= -1
