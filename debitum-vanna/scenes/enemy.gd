extends CharacterBody2D

# --- Variables de Vida ---
@export var max_health: int = 3 # Vida total del enemigo
var current_health: int

# --- Variables de Movimiento y Ataque ---
@export var velocidad: float = 60.0
@export var velocidad_ataque: float = 1000.0
@export var dano: int = 1
@export var tiempo_entre_ataques: float = 1.5
@export var tiempo_patrol: float = 2.0
@export var duracion_animacion_golpe: float = 0.3

# --- Nodos @onready ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var temporizador_ataque: Timer = $Timer
@onready var temporizador_patruya: Timer = $PatrolTimer
@onready var attack_area: Area2D = $AttackArea
@onready var vision_area: Area2D = $VisionArea
@onready var animacion_ataque_timer: Timer = $PunchTimer # Timer para la duración del golpe

# --- Variables de Estado ---
var jugador: Node2D = null
var jugador_en_vision: bool = false
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var direccion: int = 1
var puede_atacar: bool = true
var atacando: bool = false # Controla si está mostrando la animación de golpe

func _ready():
	current_health = max_health
	# Timers de Cadencia y Patrulla
	temporizador_ataque.wait_time = tiempo_entre_ataques
	temporizador_ataque.one_shot = true
	temporizador_ataque.timeout.connect(_on_temporizador_ataque_timeout)
	
	temporizador_patruya.wait_time = tiempo_patrol
	temporizador_patruya.one_shot = false
	temporizador_patruya.timeout.connect(_on_temporizador_patruya_timeout)
	temporizador_patruya.start()
	
	# Timer de Animación de Golpe
	animacion_ataque_timer.wait_time = duracion_animacion_golpe
	animacion_ataque_timer.one_shot = true
	animacion_ataque_timer.timeout.connect(_on_animacion_ataque_timer_timeout)
	
	# Conexiones
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)
	
	if vision_area:
		vision_area.body_entered.connect(_on_vision_area_body_entered)
		vision_area.body_exited.connect(_on_vision_area_body_exited)

func _physics_process(delta):
	# 1. BÚSQUEDA DEL JUGADOR
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")
		
	# 2. GRAVEDAD
	if not is_on_floor():
		velocity.y += gravedad * delta
	
	velocity.x = 0
		
	# 3. LÓGICA DE COMPORTAMIENTO
	if atacando:
		# Se queda quieto durante el Timer de Animación de golpe
		velocity.x = 0
		sprite.play("punch")
	elif jugador_en_vision and jugador != null:
		# PERSEGUIR
		var dir = sign(jugador.global_position.x - global_position.x)
		var distancia = global_position.distance_to(jugador.global_position)
		
		if distancia <= 80:
			velocity.x = dir * velocidad_ataque
		else:
			velocity.x = dir * velocidad
		
		sprite.flip_h = dir < 0
		sprite.play("attack")
	else:
		# PATRULLAR
		patrullar()
	
	# 4. APLICAR MOVIMIENTO
	move_and_slide()

func patrullar():
	if not atacando:
		velocity.x = direccion * velocidad
		sprite.play("walk")
		sprite.flip_h = direccion < 0

# ========== FUNCIONES DE VIDA Y MUERTE ==========

# Función llamada por la bala del jugador
func take_damage(damage_amount: int):
	current_health -= damage_amount
	if current_health <= 0:
		die()
		print("❌ Enemigo golpeado. Vida restante: ", current_health)

func die():
	queue_free()
	print("💀 Enemigo Eliminado.")

# ========== SEÑALES DE VISION AREA ==========
func _on_vision_area_body_entered(body):
	if body.is_in_group("player"):
		jugador_en_vision = true

func _on_vision_area_body_exited(body):
	if body.is_in_group("player"):
		jugador_en_vision = false

# ========== SEÑALES DE ATTACK AREA ==========
func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and puede_atacar:
		print("💥 Enemy: ¡INICIO DE ATAQUE!")
		
		atacando = true
		puede_atacar = false
		velocity.x = 0
		
		# 1. Inicia el Timer de CADENCIA (Cooldown entre ataques)
		temporizador_ataque.start()
		
		# 2. Inicia el Timer de ANIMACIÓN (Duración del golpe visual)
		animacion_ataque_timer.start()
		
		# Aplicar daño y Knockback al jugador
		if body.has_method("recibir_dano_knockback"):
			body.recibir_dano_knockback(dano, self.global_position)
		
		# Restar vida del nivel
		var level = get_tree().get_current_scene()
		if level.has_method("lose_life"):
			level.lose_life()

func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		print("🚶 Enemy: Jugador salió del área de ataque")
		# No resetear 'atacando' aquí, el Timer de animación lo hará.
		pass 

# ========== TIMERS DE ATAQUE ==========

func _on_animacion_ataque_timer_timeout():
	atacando = false 

func _on_temporizador_ataque_timeout():
	# Se activa cuando el cooldown entre ataques termina
	puede_atacar = true

func _on_temporizador_patruya_timeout():
	if not atacando and not jugador_en_vision:
		direccion *= -1
