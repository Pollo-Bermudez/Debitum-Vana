extends CharacterBody2D

@export var move_speed: float = 200.0
@export var jump_speed: float = 700.0
@export var knockback_force: float = 800.0
@export var knockback_vertical_boost: float = 600.0

# --- Variables de Dash ---
@export var dash_speed: float = 1200.0
@export var dash_duration: float = 0.15 # Cuántos segundos dura
# -------------------------

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var camera: Camera2D = $Camera2D
@onready var dash_timer: Timer = $DashTimer # <-- NUEVO: Referencia al nodo Timer para la duración del dash

var is_facing_right = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_stunned: bool = false
var knockback_timer: Timer = null

# --- Estados de Dash ---
var is_dashing: bool = false 
var has_dashed_in_air: bool = false
# -----------------------

func _ready():
	add_to_group("player")
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	# Configurar el timer del dash con nuestra variable @export
	dash_timer.wait_time = dash_duration # <-- NUEVO
	
	# El timer de knockback sigue creándose en código (como lo tenías)
	# Lo movemos aquí para que siempre exista y no se cree en cada golpe.
	knockback_timer = Timer.new() # <-- MODIFICADO: Quitamos el "if null" y creamos siempre.
	add_child(knockback_timer)
	knockback_timer.one_shot = true
	knockback_timer.wait_time = 0.2
	knockback_timer.timeout.connect(_on_knockback_timer_timeout)


func _physics_process(delta):
	jump(delta)
	
	if is_on_floor():
		has_dashed_in_air = false
	# --- Lógica de Dash ---
	# Permite dash si no está ya haciendo dash, no está aturdido y está en el suelo.
	# Puedes quitar "and is_on_floor()" si quieres hacer dash en el aire.
	if Input.is_action_just_pressed("dash") and not is_dashing and not is_stunned and not has_dashed_in_air: 
		start_dash()
	# -----------------------
	
	if is_dashing:
		# No hacemos nada más, el dash maneja la velocidad
		pass
	elif not is_stunned:
		move_x()
		
	flip()
	update_animations()
	move_and_slide()
	
func update_animations():
	# --- Animación de Dash ---
	if is_dashing: 
		animated_sprite.play("dash") 
		return 
	# -------------------------
		
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
	# Prevenir salto durante el dash
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_stunned and not is_dashing: # <-- MODIFICADO
		velocity.y = -jump_speed
		
	if not is_on_floor():
		velocity.y += gravity * delta

func flip():
	# Prevenir flip durante el dash (opcional, pero se ve mejor)
	if is_dashing: return # <-- NUEVO
	
	if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
		animated_sprite.flip_h = not animated_sprite.flip_h
		is_facing_right = not is_facing_right

func move_x():
	var input_axis = Input.get_axis("move_left", "move_right")
	velocity.x = input_axis * move_speed
	
# ----------------------------------------------------------------------
# NUEVAS FUNCIONES DE DASH
# ----------------------------------------------------------------------

func start_dash():
	is_dashing = true
	if not is_on_floor():
		has_dashed_in_air = true
	# Determinar dirección del dash
	var dash_direction = 1.0
	if not is_facing_right:
		dash_direction = -1.0
	
	# Opcional: permitir que la tecla de movimiento elija la dirección
	# var input_axis = Input.get_axis("move_left", "move_right")
	# if input_axis != 0:
	# 	dash_direction = sign(input_axis)

	velocity.x = dash_direction * dash_speed
	velocity.y = 0 # Dash horizontal, ignora gravedad temporalmente (o hazlo más fuerte si quieres dash en el aire)
	
	dash_timer.start() # Inicia el timer que determinará la duración del dash

# Esta función se conectó desde el editor (Paso 3 en las instrucciones anteriores)
func _on_dash_timer_timeout():
	is_dashing = false
	# Detenerse bruscamente al final del dash
	velocity.x = 0
	# Si quieres un desvanecimiento de la velocidad, podrías poner velocity.x = velocity.x * 0.5 o similar.

# ----------------------------------------------------------------------
# FUNCIONES DE DAÑO Y KNOCKBACK
# ----------------------------------------------------------------------

func recibir_dano_knockback(cantidad: int, enemy_position: Vector2):
	print("🔥 El jugador recibió ", cantidad, " de daño y retrocede.")

	# 1. Aplicar fuerza de retroceso
	is_stunned = true
	var push_direction = sign(global_position.x - enemy_position.x)
	velocity.x = push_direction * knockback_force
	velocity.y = -knockback_vertical_boost
	
	# 2. Iniciar Timer de aturdimiento
	# Si el timer ya está corriendo, no lo reiniciamos.
	if knockback_timer.is_stopped(): # <-- MODIFICADO
		knockback_timer.start()

	# 3. Restar vida (Llama al nivel)
	var nivel = get_tree().get_current_scene()
	if nivel and nivel.has_method("lose_life"):
		nivel.lose_life()

func _on_knockback_timer_timeout():
	is_stunned = false
	if is_on_floor(): # Solo ponemos velocity.x a 0 si está en el suelo.
		velocity.x = 0
	# El timer ya es un nodo @onready y se maneja solo.
