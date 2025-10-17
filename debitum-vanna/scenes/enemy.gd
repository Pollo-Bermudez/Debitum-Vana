extends CharacterBody2D

@export var velocidad: float = 60.0
@export var velocidad_ataque: float = 1000.0
@export var dano: int = 1
@export var tiempo_entre_ataques: float = 1.5
@export var tiempo_patrol: float = 2.0
@export var duracion_animacion_golpe: float = 0.3 # 🆕 Duración que quieres que se vea el golpe

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var temporizador_ataque: Timer = $Timer
@onready var temporizador_patruya: Timer = $PatrolTimer
@onready var attack_area: Area2D = $AttackArea
@onready var vision_area: Area2D = $VisionArea
@onready var animacion_ataque_timer: Timer = $PunchTimer # 🆕 Nuevo Timer

var jugador: Node2D = null
var jugador_en_vision: bool = false
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var direccion: int = 1
var puede_atacar: bool = true
var atacando: bool = false

func _ready():
	# Timers de Cadencia y Patrulla (Existentes)
	temporizador_ataque.wait_time = tiempo_entre_ataques
	temporizador_ataque.one_shot = true
	temporizador_ataque.timeout.connect(_on_temporizador_ataque_timeout)
	
	temporizador_patruya.wait_time = tiempo_patrol
	temporizador_patruya.one_shot = false
	temporizador_patruya.timeout.connect(_on_temporizador_patruya_timeout)
	temporizador_patruya.start()
	
	# 🆕 Timer de Animación de Golpe
	animacion_ataque_timer.wait_time = duracion_animacion_golpe
	animacion_ataque_timer.one_shot = true
	animacion_ataque_timer.timeout.connect(_on_animacion_ataque_timer_timeout)
	
	# Conectar señales del AttackArea y VisionArea
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
		# Se queda quieto durante el Timer de Animación
		velocity.x = 0
		sprite.play("punch") # Asegura que la animación se siga reproduciendo
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

# ========== SEÑALES DE VISION AREA (Sin Cambios) ==========
func _on_vision_area_body_entered(body):
	if body.is_in_group("player"):
		jugador_en_vision = true

func _on_vision_area_body_exited(body):
	if body.is_in_group("player"):
		jugador_en_vision = false

# ========== SEÑALES DE ATTACK AREA (Ajuste del Timer) ==========
func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and puede_atacar:
		print("💥 Enemy: ¡INICIO DE ATAQUE!")
		
		atacando = true # Activa el estado de detención y animación
		puede_atacar = false
		velocity.x = 0
		
		# 1. Inicia el Timer de CADENCIA (controla el tiempo entre golpes)
		temporizador_ataque.start()
		
		# 2. Inicia el Timer de ANIMACIÓN (controla cuánto tiempo se ve el golpe)
		animacion_ataque_timer.start()
		
		# Aplicar daño y Knockback
		if body.has_method("recibir_dano_knockback"):
			body.recibir_dano_knockback(dano, self.global_position)
		
		var level = get_tree().get_current_scene()
		if level.has_method("lose_life"):
			level.lose_life()

func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		print("🚶 Enemy: Jugador salió del área de ataque")
		# 🛑 NOTA: No resetear 'atacando' aquí, el Timer lo hará para la animación.
		pass 

# ========== TIMERS DE ATAQUE ==========

# 🆕 Timeout del Timer de Animación (Determina cuándo termina la animación de golpe)
func _on_animacion_ataque_timer_timeout():
	print("🎬 Animación de golpe terminada. Volviendo a idle/correr.")
	# El estado 'atacando' se resetea aquí, permitiendo el movimiento
	atacando = false 
	# El 'temporizador_ataque' sigue corriendo para el tiempo de recarga

# Timeout del Timer de Cadencia (Determina cuándo puede volver a golpear)
func _on_temporizador_ataque_timeout():
	puede_atacar = true
	print("⏰ Enemy: ¡Recarga completa! Puede atacar de nuevo.")

func _on_temporizador_patruya_timeout():
	if not atacando and not jugador_en_vision:
		direccion *= -1
