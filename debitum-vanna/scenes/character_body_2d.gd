extends CharacterBody2D

@export var move_speed: float = 200.0
@export var jump_speed: float = 700.0
@export var knockback_force: float = 800.0
@export var knockback_vertical_boost: float = 600.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var camera: Camera2D = $Camera2D

var is_facing_right = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_stunned: bool = false
var knockback_timer: Timer = null # Variable para almacenar la referencia al Timer

func _ready():
	add_to_group("player")
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0

func _physics_process(delta):
	jump(delta)
	
	if not is_stunned:
		move_x()
		
	flip()
	update_animations()
	move_and_slide()
	
func update_animations():
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
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_stunned:
		velocity.y = -jump_speed
		
	if not is_on_floor():
		velocity.y += gravity * delta

func flip():
	if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
		animated_sprite.flip_h = not animated_sprite.flip_h
		is_facing_right = not is_facing_right

func move_x():
	var input_axis = Input.get_axis("move_left", "move_right")
	velocity.x = input_axis * move_speed
	
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
	
	# 2. Iniciar Timer de aturdimiento si no está corriendo
	if knockback_timer == null:
		knockback_timer = Timer.new()
		add_child(knockback_timer)
		knockback_timer.one_shot = true
		knockback_timer.wait_time = 0.2
		knockback_timer.timeout.connect(_on_knockback_timer_timeout)
		knockback_timer.start()

	# 3. Restar vida (Llama al nivel)
	var nivel = get_tree().get_current_scene()
	if nivel and nivel.has_method("lose_life"):
		nivel.lose_life()

func _on_knockback_timer_timeout():
	is_stunned = false
	if is_on_floor():
		velocity.x = 0
	
	# Eliminar la referencia al Timer para permitir crear uno nuevo si es golpeado de nuevo
	if knockback_timer:
		knockback_timer.queue_free()
		knockback_timer = null
