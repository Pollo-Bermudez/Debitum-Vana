extends Camera2D

extends CharacterBody2D

@export var move_speed: float = 280.0
@export var jump_speed: float = 780.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_facing_right = true

func _ready():
	camera.enabled = true
	camera.position_smoothing_enabled = true

func _physics_process(delta):
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Movimiento horizontal
	var input_dir = Input.get_axis("ui_left", "ui_right")
	velocity.x = input_dir * move_speed
	
	# Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_speed
	
	# Voltear sprite
	if input_dir != 0:
		is_facing_right = input_dir > 0
		animated_sprite.flip_h = !is_facing_right
	
	# Animaciones
	update_animations()
	
	# Mover
	move_and_slide()

func update_animations():
	if is_on_floor():
		if abs(velocity.x) > 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")
	else:
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
