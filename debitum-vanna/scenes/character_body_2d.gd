extends CharacterBody2D

@export var move_speed: float = 200.0
@export var jump_speed: float = 700.0
@export var knockback_force: float = 800.0
@export var knockback_vertical_boost: float = 600.0

# --- Variables de Dash ---
@export var dash_speed: float = 1200.0
@export var dash_duration: float = 0.15
# -------------------------

# --- Variables de Disparo ---
@export var shoot_cooldown: float = 0.4                  # Tiempo de recarga
@export var bullet_scene: PackedScene                    # Escena de la bala
# ----------------------------

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var camera: Camera2D = $Camera2D
@onready var dash_timer: Timer = $DashTimer
@onready var shoot_timer: Timer = $ShootTimer            # 🛑 NUEVO: Referencia al nodo Timer de Disparo

var is_facing_right = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_stunned: bool = false
var knockback_timer: Timer = null                        # Usado para crear el Timer en _ready
var can_shoot: bool = true                              # 🛑 NUEVO: Bandera para disparar

# --- Estados de Dash ---
var is_dashing: bool = false
var has_dashed_in_air: bool = false
# -----------------------

func _ready():
	add_to_group("player")
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	# Configuración del Timer de Dash
	dash_timer.wait_time = dash_duration
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	
	# 🛑 Configuración del Timer de Disparo
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	# Configuración del Timer de Knockback
	knockback_timer = Timer.new()
	add_child(knockback_timer)
	knockback_timer.one_shot = true
	knockback_timer.wait_time = 0.2
	knockback_timer.timeout.connect(_on_knockback_timer_timeout)


func _physics_process(delta):
	jump(delta)
	
	if is_on_floor():
		has_dashed_in_air = false
		
	# --- Lógica de Dash ---
	if Input.is_action_just_pressed("dash") and not is_dashing and not is_stunned and not has_dashed_in_air:
		start_dash()
	# -----------------------
	
	if is_dashing:
		# En dash, solo aplicamos el movimiento del dash
		pass
	elif not is_stunned:
		move_x()
		handle_shooting() # 🛑 Llamar a la lógica de disparo
		
	flip()
	update_animations()
	move_and_slide()
	
func update_animations():
	# --- Animación de Dash ---
	if is_dashing:
		animated_sprite.flip_h = true
		animated_sprite.play("dash")
		return
	# -------------------------
	
	# 🛑 Animación de Disparo (Launch)
	if not can_shoot and shoot_timer.time_left > 0.0: # Muestra launch mientras el cooldown está activo
		animated_sprite.play("launch")
		return
		
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
		return
		
	if abs(velocity.x) > 10:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

func jump(delta):
	# Prevenir salto durante el dash y aturdimiento
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_stunned and not is_dashing:
		velocity.y = -jump_speed
		
	if not is_on_floor():
		velocity.y += gravity * delta

func flip():
	# Prevenir flip durante el dash
	if is_dashing: return
	
	if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
		animated_sprite.flip_h = not animated_sprite.flip_h
		is_facing_right = not is_facing_right

func move_x():
	var input_axis = Input.get_axis("move_left", "move_right")
	velocity.x = input_axis * move_speed
	
# ----------------------------------------------------------------------
# FUNCIONES DE DASH
# ----------------------------------------------------------------------

func start_dash():
	is_dashing = true
	if not is_on_floor():
		has_dashed_in_air = true
	
	var dash_direction = 1.0
	if not is_facing_right:
		dash_direction = -1.0

	velocity.x = dash_direction * dash_speed
	velocity.y = 0
	
	dash_timer.start()

func _on_dash_timer_timeout():
	is_dashing = false
	velocity.x = 0

# ----------------------------------------------------------------------
# 🛑 FUNCIONES DE DISPARO
# ----------------------------------------------------------------------

func handle_shooting():
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

func shoot():
	if bullet_scene == null:
		push_warning("Bullet scene no está asignada.")
		return
		
	# 1. Iniciar Cooldown
	can_shoot = false
	shoot_timer.start()
	
	# 2. Instanciar la bala
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)

	# 3. Posicionar la bala
	var shoot_offset = Vector2(20, -10) # Ajusta este offset
	if not is_facing_right:
		shoot_offset.x *= -1

	bullet.global_position = global_position + shoot_offset

	# 4. Darle velocidad
	var direction = 1 if is_facing_right else -1
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction)

func _on_shoot_timer_timeout():
	can_shoot = true

# ----------------------------------------------------------------------
# FUNCIONES DE DAÑO Y KNOCKBACK
# ----------------------------------------------------------------------

func recibir_dano_knockback(cantidad: int, enemy_position: Vector2):
	# Prevenir knockback si estás haciendo dash (comportamiento común de invencibilidad)
	if is_dashing: return 
	
	print("🔥 El jugador recibió ", cantidad, " de daño y retrocede.")

	# 1. Aplicar fuerza de retroceso
	is_stunned = true
	var push_direction = sign(global_position.x - enemy_position.x)
	velocity.x = push_direction * knockback_force
	velocity.y = -knockback_vertical_boost
	
	# 2. Iniciar Timer de aturdimiento
	if knockback_timer.is_stopped():
		knockback_timer.start()

	# 3. Restar vida (Llama al nivel)
	var nivel = get_tree().get_current_scene()
	if nivel and nivel.has_method("lose_life"):
		nivel.lose_life()

func _on_knockback_timer_timeout():
	is_stunned = false
	if is_on_floor():
		velocity.x = 0
