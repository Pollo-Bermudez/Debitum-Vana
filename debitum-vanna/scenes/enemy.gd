extends CharacterBody2D

# ==========================================
# CONFIGURACIÓN (VARIABLES EDITABLES)
# ==========================================

# --- Variables de Vida ---
@export var max_health: int = 6 # Vida total del enemigo
var current_health: int

# --- Variables de Movimiento y Ataque ---
@export var velocidad_patrulla: float = 60.0   # Velocidad tranquila al patrullar
@export var velocidad_ataque: float = 200.0    # Velocidad rápida al perseguir (Bajé 1000 a 200, 1000 es demasiado rápido)
@export var distancia_frenado: float = 40.0    # Distancia a la que se detiene frente al jugador para no chocar
@export var dano: int = 1
@export var tiempo_entre_ataques: float = 1.5
@export var tiempo_patrol: float = 2.0
@export var duracion_animacion_golpe: float = 0.3

# ==========================================
# NODOS INTERNOS
# ==========================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var temporizador_ataque: Timer = $Timer
@onready var temporizador_patruya: Timer = $PatrolTimer
@onready var attack_area: Area2D = $AttackArea
@onready var vision_area: Area2D = $VisionArea
@onready var animacion_ataque_timer: Timer = $PunchTimer 
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D # Asegúrate de tener este nodo si lo usas

# ==========================================
# ESTADOS DEL ENEMIGO
# ==========================================
var jugador: Node2D = null
var jugador_en_vision: bool = false
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var direccion: int = 1         # 1 derecha, -1 izquierda
var puede_atacar: bool = true  # Controla el Cooldown (tiempo entre golpes)
var atacando: bool = false     # Controla si la animación de golpe está activa

# ==========================================
# INICIALIZACIÓN
# ==========================================
func _ready():
	current_health = max_health
	
	# Configuración del Timer de Cooldown de ataque
	temporizador_ataque.wait_time = tiempo_entre_ataques
	temporizador_ataque.one_shot = true
	temporizador_ataque.timeout.connect(_on_temporizador_ataque_timeout)
	
	# Configuración del Timer de Patrullaje (cambio de dirección)
	temporizador_patruya.wait_time = tiempo_patrol
	temporizador_patruya.one_shot = false
	temporizador_patruya.timeout.connect(_on_temporizador_patruya_timeout)
	temporizador_patruya.start()
	
	# Configuración del Timer visual del golpe
	animacion_ataque_timer.wait_time = duracion_animacion_golpe
	animacion_ataque_timer.one_shot = true
	animacion_ataque_timer.timeout.connect(_on_animacion_ataque_timer_timeout)
	
	# Conectar señales de las áreas de forma segura
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)
	
	if vision_area:
		vision_area.body_entered.connect(_on_vision_area_body_entered)
		vision_area.body_exited.connect(_on_vision_area_body_exited)

# ==========================================
# BUCLE DE FÍSICAS (SE EJECUTA CADA FRAME)
# ==========================================
func _physics_process(delta):
	# Busca al jugador si no lo tiene referenciado
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")
	
	# Aplicar gravedad si está en el aire
	if not is_on_floor():
		velocity.y += gravedad * delta
	
	# Resetear velocidad X por defecto (para que no deslice)
	velocity.x = 0
	
	# --- MÁQUINA DE ESTADOS SIMPLE ---
	
	# ESTADO 1: ATACANDO (Prioridad máxima)
	# Si está lanzando el golpe, se queda quieto.
	if atacando:
		velocity.x = 0
		# Nota: La animación y sonido se activaron al entrar al área de ataque
	
	# ESTADO 2: PERSIGUIENDO
	# Si ve al jugador y existe, lo persigue.
	elif jugador_en_vision and jugador != null:
		perseguir()
	
	# ESTADO 3: PATRULLANDO
	# Si no pasa nada de lo anterior, camina tranquilo.
	else:
		patrullar()
	
	# Aplicar el movimiento final
	move_and_slide()

# ==========================================
# LÓGICA DE MOVIMIENTO
# ==========================================

func perseguir():
	# Calcular distancia al jugador
	var distancia = global_position.distance_to(jugador.global_position)
	# Calcular dirección (-1 izquierda, 1 derecha)
	var dir = sign(jugador.global_position.x - global_position.x)
	
	# Voltear el sprite hacia el jugador
	if dir != 0:
		sprite.flip_h = dir < 0
	
	# LÓGICA DE FRENADO:
	# Si estamos lejos, corremos rápido.
	if distancia > distancia_frenado:
		velocity.x = dir * velocidad_ataque
		sprite.play("attack") # O usa una animación de "correr" si tienes
	else:
		# Si estamos muy cerca (dentro del rango de frenado), nos detenemos
		# pero seguimos mirando al jugador (sprite.flip_h ya se ajustó arriba)
		velocity.x = 0
		sprite.play("idle") # O una animación de "guardia"

func patrullar():
	# Si está atacando no debe moverse (seguridad extra)
	if atacando:
		return
	
	# Movimiento simple de lado a lado
	velocity.x = direccion * velocidad_patrulla
	
	# Animación y orientación
	sprite.play("walk")
	sprite.flip_h = direccion < 0

# ==========================================
# SISTEMA DE VIDA Y DAÑO
# ==========================================

# Función para recibir daño (desde el jugador)
func take_damage(damage_amount: int):
	current_health -= damage_amount
	if current_health <= 0:
		die()
		print("❌ Enemigo golpeado. Vida restante: ", current_health)

func die():
	queue_free() # Elimina al enemigo del juego
	print("💀 Enemigo Eliminado.")

# ==========================================
# DETECCIÓN DE VISIÓN
# ==========================================
func _on_vision_area_body_entered(body):
	if body.is_in_group("player"):
		jugador_en_vision = true

func _on_vision_area_body_exited(body):
	if body.is_in_group("player"):
		jugador_en_vision = false

# ==========================================
# SISTEMA DE COMBATE (ÁREA DE ATAQUE)
# ==========================================
func _on_attack_area_body_entered(body):
	# Verifica si es el jugador y si el cooldown permite atacar
	if body.is_in_group("player") and puede_atacar:
		iniciar_ataque(body)

func iniciar_ataque(objetivo):
	print("💥 Enemy: ¡INICIO DE ATAQUE!")
	
	atacando = true       # Bloquea movimiento en _physics_process
	puede_atacar = false  # Inicia cooldown
	velocity.x = 0        # Frena en seco
	
	# Reproducir sonido si existe
	if audio_player:
		audio_player.play()
		
	# Reproducir animación
	sprite.play("punch")
	
	# Iniciar Timers
	temporizador_ataque.start()       # Tiempo hasta el próximo ataque posible
	animacion_ataque_timer.start()    # Tiempo que dura la animación de golpe ("punch")
	
	# Aplicar Daño y Empuje
	if objetivo.has_method("recibir_dano_knockback"):
		objetivo.recibir_dano_knockback(dano, self.global_position)

func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		print("🚶 Enemy: Jugador salió del área de ataque")

# ==========================================
# MANEJO DE TIMERS (TIEMPO)
# ==========================================

# Se acaba la animación visual del golpe (e.g. 0.3 seg)
func _on_animacion_ataque_timer_timeout():
	atacando = false 
	# Ahora el enemigo puede volver a moverse en _physics_process

# Se acaba el tiempo de descanso entre ataques (e.g. 1.5 seg)
func _on_temporizador_ataque_timeout():
	puede_atacar = true
	# Si el jugador sigue en el área, intentamos atacar de nuevo inmediatamente
	# (Verificamos si hay cuerpos solapados en el área de ataque)
	if attack_area.has_overlapping_bodies():
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				iniciar_ataque(body)
				break

# Timer para cambiar de dirección al patrullar
func _on_temporizador_patruya_timeout():
	# Solo cambia de dirección si NO está persiguiendo ni atacando
	if not atacando and not jugador_en_vision:
		direccion *= -1
