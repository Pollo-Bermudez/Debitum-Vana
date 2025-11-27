extends CharacterBody2D

# CONFIGURACIÓN
@export var max_health: int = 6
var current_health: int

@export var velocidad_patrulla: float = 60.0
@export var velocidad_ataque: float = 200.0
@export var distancia_frenado: float = 40.0
@export var dano: int = 2
@export var tiempo_entre_ataques: float = 1.5
@export var tiempo_patrol: float = 2.0
@export var duracion_animacion_golpe: float = 0.3

# NODOS
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var temporizador_ataque: Timer = $Timer
@onready var temporizador_patruya: Timer = $PatrolTimer
@onready var attack_area: Area2D = $AttackArea
@onready var vision_area: Area2D = $VisionArea
@onready var animacion_ataque_timer: Timer = $PunchTimer 
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# ESTADO
var jugador: Node2D = null
var jugador_en_vision: bool = false
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var direccion: int = 1
var puede_atacar: bool = true
var atacando: bool = false

# Mapeo: true = frames dibujados mirando a la derecha (base_right)
var anim_base_facing = {
	"walk": false,   # Ajusta si tus walk están dibujados mirando a la derecha/izquierda
	"idle": false,
	"attack": true   # SEGÚN TU CAPTURA -> attack mira a la DERECHA
}

# --------------------
func _ready():
	current_health = max_health

	temporizador_ataque.wait_time = tiempo_entre_ataques
	temporizador_ataque.one_shot = true
	temporizador_ataque.timeout.connect(_on_temporizador_ataque_timeout)
	
	temporizador_patruya.wait_time = tiempo_patrol
	temporizador_patruya.one_shot = false
	temporizador_patruya.timeout.connect(_on_temporizador_patruya_timeout)
	temporizador_patruya.start()

	animacion_ataque_timer.wait_time = duracion_animacion_golpe
	animacion_ataque_timer.one_shot = true
	animacion_ataque_timer.timeout.connect(_on_animacion_ataque_timer_timeout)

	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)

	if vision_area:
		vision_area.body_entered.connect(_on_vision_area_body_entered)
		vision_area.body_exited.connect(_on_vision_area_body_exited)

# --------------------
func _physics_process(delta):
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")

	if not is_on_floor():
		velocity.y += gravedad * delta

	velocity.x = 0

	if atacando:
		velocity.x = 0
	elif jugador_en_vision and jugador != null:
		perseguir()
	else:
		patrullar()

	# Control del flip: solo aplicar aquí si NO estamos en la animación de ataque
	if not atacando:
		var dir = sign(velocity.x)
		if dir != 0:
			_apply_flip_for_direction(dir)
		else:
			# quieto: mirar al jugador si existe
			if jugador:
				var dir_to_player = sign(jugador.global_position.x - global_position.x)
				if dir_to_player != 0:
					_apply_flip_for_direction(dir_to_player)

	move_and_slide()

# --------------------
# Helpers de animación / flip
func play_anim(anim_name: String) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)

# dir: -1 = izquierda, 1 = derecha
func _apply_flip_for_direction(dir: int) -> void:
	if dir == 0:
		return
	var anim = sprite.animation
	var base_right: bool = true
	if anim in anim_base_facing:
		base_right = anim_base_facing[anim]
	# Queremos que el personaje mire hacia la derecha si dir > 0.
	# Si dibujo base ya mira a la derecha -> flip_h = false cuando dir>0
	# Si dibujo base mira a la izquierda  -> flip_h = true  cuando dir>0
	# Expresión equivalente: flip_h = (dir > 0) != base_right
	sprite.flip_h = (dir > 0) != base_right

func _face_position(pos: Vector2) -> void:
	var dir = sign(pos.x - global_position.x)
	if dir == 0:
		dir = direccion
	_apply_flip_for_direction(dir)

# --------------------
# MOVIMIENTO
func perseguir():
	if jugador == null:
		return
	var distancia = global_position.distance_to(jugador.global_position)
	var dir = sign(jugador.global_position.x - global_position.x)
	
	if distancia > distancia_frenado:
		velocity.x = dir * velocidad_ataque
		play_anim("walk")
		_apply_flip_for_direction(sign(velocity.x))
	else:
		velocity.x = 0
		play_anim("idle")
		_face_position(jugador.global_position)

func patrullar():
	if atacando:
		return
	velocity.x = direccion * velocidad_patrulla
	play_anim("walk")
	_apply_flip_for_direction(sign(velocity.x))

# --------------------
# VIDA
func take_damage(damage_amount: int):
	current_health -= damage_amount
	if current_health <= 0:
		die()

func die():
	queue_free()

# --------------------
# VISION
func _on_vision_area_body_entered(body):
	if body.is_in_group("player"):
		jugador_en_vision = true

func _on_vision_area_body_exited(body):
	if body.is_in_group("player"):
		jugador_en_vision = false

# --------------------
# ATAQUE
func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and puede_atacar:
		iniciar_ataque(body)

func iniciar_ataque(objetivo):
	atacando = true
	puede_atacar = false
	velocity.x = 0

	# IMPORTANTE: usar la posición del objetivo para fijar flip según el base de la animación "attack"
	play_anim("attack")
	# Aquí calculamos la dirección hacia el objetivo y aplicamos flip según base de "attack"
	if objetivo:
		var dir = sign(objetivo.global_position.x - global_position.x)
		if dir == 0:
			dir = direccion
		# Como "attack" está mapeada en anim_base_facing, _apply_flip_for_direction hará lo correcto
		_apply_flip_for_direction(dir)

	if audio_player:
		audio_player.play()

	temporizador_ataque.start()
	animacion_ataque_timer.start()

	if objetivo.has_method("recibir_dano_knockback"):
		objetivo.recibir_dano_knockback(dano, self.global_position)

func _on_attack_area_body_exited(_body):
	pass

# --------------------
# TIMERS
func _on_animacion_ataque_timer_timeout():
	atacando = false

func _on_temporizador_ataque_timeout():
	puede_atacar = true
	if attack_area.has_overlapping_bodies():
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				iniciar_ataque(body)
				break

func _on_temporizador_patruya_timeout():
	if not atacando and not jugador_en_vision:
		direccion *= -1
