extends CharacterBody2D

@export var move_speed: float = 200.0
@export var jump_speed: float = 700.0
@export var knockback_force: float = 700.0
@export var knockback_vertical_boost: float = 400.0

# --- Variables de Dash ---
@export var dash_speed: float = 1200.0
@export var dash_duration: float = 0.15
# -------------------------

# --- Variables de Disparo ---
@export var shoot_cooldown: float = 0.1			# Tiempo de recarga
@export var bullet_scene: PackedScene			# Escena de la bala
# ----------------------------

#------ Variable de muerte -----
@export var death_animation_duration: float = 1.0
#--------------------------------

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var camera: Camera2D = $Camera2D
@onready var dash_timer: Timer = $DashTimer
@onready var shoot_timer: Timer = $ShootTimer		# Referencia al nodo Timer de Disparo

var is_facing_right = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 1.3
var is_stunned: bool = false
var knockback_timer: Timer = null			# Usado para crear el Timer en _ready
var can_shoot: bool = true					# Bandera para disparar
var is_dead: bool = false 

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
	# dash_timer.timeout.connect(_on_dash_timer_timeout)
	
	# Configuración del Timer de Disparo
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	# Configuración del Timer de Knockback
	knockback_timer = Timer.new()
	add_child(knockback_timer)
	knockback_timer.one_shot = true
	knockback_timer.wait_time = 0.2
	knockback_timer.timeout.connect(_on_knockback_timer_timeout)


# ======================================================================
# 						PROCESO PRINCIPAL (CORREGIDO)
# ======================================================================

func _physics_process(delta):	
	# --- ¡LÓGICA DE MUERTE! ---
	if is_dead:
		# Si estamos muertos, lo único que hacemos es caer.
		apply_gravity(delta)
		# Revisamos si hemos tocado el suelo:
		if is_on_floor():
			# Si tocamos el suelo Y la animación "die" NO se está
			# reproduciendo ya, la iniciamos.
			if animated_sprite.animation != "die":
				start_death_animation_on_ground()
		
		# Aplicamos la física (para caer) y no hacemos nada más
		move_and_slide()
		return # <-- Detiene el resto de la función
	
	# 1. Aplicar gravedad SÓLO si no estamos muertos/aturdidos
	if not is_stunned:
		apply_gravity(delta)
	
	# 2. Manejar el input de salto (ya está protegido por is_stunned por dentro)
	handle_jump() # <-- Llama a la nueva función
	
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
		# Mover y disparar solo si no estamos aturdidos
		move_x()
		handle_shooting()
		
	flip()
	update_animations()
	move_and_slide()

# ======================================================================
# 						FUNCIONES DE MOVIMIENTO (CORREGIDAS)
# ======================================================================

func update_animations():
	# ¡CORRECCIÓN CLAVE!
	# Si estamos aturdidos (muriendo o por knockback), no anular la animación.
	if is_stunned: 
		return
		
	# --- Animación de Dash ---
	if is_dashing:
		animated_sprite.play("dash")
		$dah.play()
		return
	# -------------------------
	
	# Animación de Disparo (Launch)
	if not can_shoot and shoot_timer.time_left > 0.0:
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

# --- ¡NUEVA FUNCIÓN! ---
func apply_gravity(delta):
	# Esta es la lógica que borramos de la vieja función jump()
	if not is_on_floor():
		velocity.y += gravity * delta

# --- ¡FUNCIÓN MODIFICADA! ---
func handle_jump(): # Ya no necesita 'delta'
	# Prevenir salto durante el dash y aturdimiento
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_stunned and not is_dashing:
		velocity.y = -jump_speed
		$jumping.play()
	# La lógica de gravedad se movió a apply_gravity(delta)

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
# FUNCIONES DE DISPARO
# ----------------------------------------------------------------------

func handle_shooting():
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

func shoot():
	if bullet_scene == null:
		push_warning("Bullet scene no está asignada.")
		return
		
	can_shoot = false
	shoot_timer.start()
	
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)

	var shoot_offset = Vector2(20, -10)
	if not is_facing_right:
		shoot_offset.x *= -1

	bullet.global_position = global_position + shoot_offset

	var direction = 1 if is_facing_right else -1
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction)

func _on_shoot_timer_timeout():
	can_shoot = true

# ======================================================================
# 				FUNCIONES DE DAÑO Y MUERTE (CORREGIDAS)
# ======================================================================

func recibir_dano_knockback(cantidad: int, enemy_position: Vector2):
	# 1. Si estamos en dash O YA ESTAMOS ATURDIDOS/MURIENDO, no recibir más daño.
	if is_dashing or is_stunned: return
	
	# 2. Restar la vida (llamar al nivel)
	var nivel = get_tree().get_current_scene()
	if nivel and nivel.has_method("lose_life"):
		nivel.lose_life()

	# 3. COMPROBAR SI MORIMOS
	# 'lose_life()' habrá llamado a 'initiate_death()', 
	# y 'initiate_death()' ya habrá puesto 'is_stunned = true'.
	if is_stunned:
		# Si morimos, 'initiate_death()' ya se encargó de todo.
		# Salimos de aquí para NO aplicar el knockback.
		return
	
	# 4. SI LLEGAMOS AQUÍ, NO MORIMOS. Aplicamos knockback.
	print("🔥 El jugador recibió ", cantidad, " de daño y retrocede.")
	is_stunned = true
	var push_direction = sign(global_position.x - enemy_position.x)
	velocity.x = push_direction * knockback_force
	velocity.y = -knockback_vertical_boost
	
	# 5. Iniciar Timer de aturdimiento
	if knockback_timer.is_stopped():
		knockback_timer.start()


func _on_knockback_timer_timeout():
	is_stunned = false
	if is_on_floor():
		velocity.x = 0

# --- ¡FUNCIÓN CLAVE! (Tu versión ya estaba correcta) ---
func initiate_death():
	# Revisamos 'is_dead' para evitar llamadas dobles
	if is_dead:
		return
		
	is_dead = true
	is_stunned = true # 'is_stunned' es perfecto para detener el input
	is_dashing = false
	
	print("--- MUERTE REGISTRADA, ESPERANDO SUELO ---")


func start_death_animation_on_ground():
	print("--- TOCANDO SUELO, INICIANDO ANIMACIÓN DE MUERTE ---")
	
	velocity = Vector2.ZERO # ¡Detenemos el movimiento!
	animated_sprite.play("die") # ¡Reproducimos la animación!
	var death_timer = Timer.new()
	add_child(death_timer)
	death_timer.one_shot = true
	
	print("El tiempo de espera es: " + str(death_animation_duration))
	death_timer.wait_time = death_animation_duration
	
	# Le decimos al timer que llame a la función CUANDO TERMINE
	death_timer.timeout.connect(_on_death_animation_finished)
	death_timer.start()


func _on_death_animation_finished():
	print("--- TIMER DE MUERTE TERMINADO ---")
	var nivel = get_tree().get_current_scene()
	if nivel and nivel.has_method("handle_player_death_cleanup"):
		nivel.handle_player_death_cleanup()
	
	queue_free()
