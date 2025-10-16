extends CharacterBody2D

@export var velocidad: float = 60.0
@export var velocidad_ataque: float = 90.0
@export var dano: int = 1
@export var tiempo_entre_ataques: float = 1.5
@export var tiempo_patrol: float = 2.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var temporizador_ataque: Timer = $Timer
@onready var temporizador_patruya: Timer = $PatrolTimer
@onready var attack_area: Area2D = $AttackArea
@onready var vision_area: Area2D = $VisionArea  # 🆕 Área de visión

var jugador: Node2D = null
var jugador_en_vision: bool = false  # 🆕 Bandera de visión
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var direccion: int = 1
var puede_atacar: bool = true
var atacando: bool = false

func _ready():
	# Timers
	temporizador_ataque.wait_time = tiempo_entre_ataques
	temporizador_ataque.one_shot = true
	temporizador_ataque.timeout.connect(_on_temporizador_ataque_timeout)
	
	temporizador_patruya.wait_time = tiempo_patrol
	temporizador_patruya.one_shot = false
	temporizador_patruya.timeout.connect(_on_temporizador_patruya_timeout)
	temporizador_patruya.start()
	
	# Conectar señales del AttackArea
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)
	
	# 🆕 Conectar señales del VisionArea
	if vision_area:
		vision_area.body_entered.connect(_on_vision_area_body_entered)
		vision_area.body_exited.connect(_on_vision_area_body_exited)

func _physics_process(delta):
	# 1. BÚSQUEDA DEL JUGADOR (solo primera vez)
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")
		if jugador != null:
			print("Enemy: ¡Jugador encontrado!")
			
	# 2. GRAVEDAD
	if not is_on_floor():
		velocity.y += gravedad * delta
	
	velocity.x = 0
		
	# 3. LÓGICA DE COMPORTAMIENTO
	if atacando:
		# Si está atacando, quedarse quieto
		velocity.x = 0
	elif jugador_en_vision and jugador != null:
		# 🆕 PERSEGUIR: Solo si el jugador está en el área de visión
		var dir = sign(jugador.global_position.x - global_position.x)
		var distancia = global_position.distance_to(jugador.global_position)
		
		# Aumentar velocidad cuando está cerca
		if distancia <= 80:  # Rango de ataque aproximado
			velocity.x = dir * velocidad_ataque
			print("⚡ Enemy: ¡ACELERANDO PARA ATACAR!")
		else:
			velocity.x = dir * velocidad
		
		sprite.flip_h = dir < 0
		sprite.play("attack")
	else:
		# PATRULLAR: Si el jugador está fuera de visión
		patrullar()
	
	# 4. APLICAR MOVIMIENTO
	move_and_slide()

func patrullar():
	if not atacando:
		velocity.x = direccion * velocidad
		sprite.play("walk")
		sprite.flip_h = direccion < 0

# ========== SEÑALES DE VISION AREA ==========
# 🆕 Cuando el jugador ENTRA al área de visión
func _on_vision_area_body_entered(body):
	if body.is_in_group("player"):
		jugador_en_vision = true
		print("👁️ Enemy: ¡Jugador detectado en rango de visión!")

# 🆕 Cuando el jugador SALE del área de visión
func _on_vision_area_body_exited(body):
	if body.is_in_group("player"):
		jugador_en_vision = false
		print("🚶 Enemy: Jugador salió del rango de visión, volviendo a patrullar")

# ========== SEÑALES DE ATTACK AREA ==========
func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and puede_atacar:
		print("💥 Enemy: ¡CONTACTO CON JUGADOR! Aplicando daño")
		
		atacando = true
		puede_atacar = false
		sprite.play("attack")
		velocity.x = 0
		
		temporizador_ataque.start()
		
		# Aplicar daño
		var level = get_tree().current_scene
		if level.has_method("handle_player_damage"):
			level.handle_player_damage()
			print("✅ Player recibió daño y fue enviado al spawn")

func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		print("🚶 Enemy: Jugador salió del área de ataque")
		atacando = false

func _on_temporizador_ataque_timeout():
	puede_atacar = true
	atacando = false
	print("⏰ Enemy: ¡Timer de ataque terminado!")

func _on_temporizador_patruya_timeout():
	if not atacando and not jugador_en_vision:
		direccion *= -1
