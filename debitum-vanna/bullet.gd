extends Area2D

@export var speed: float = 800.0
@export var damage: int = 1

var direction: int = 1 # 1 para derecha, -1 para izquierda

func _ready():
	# Conectar la señal de colisión (solo se destruye si golpea algo que no sea el player)
	body_entered.connect(_on_body_entered)
	
func _process(delta):
	# Mueve la bala en la dirección asignada
	global_position.x += speed * direction * delta

func set_direction(dir: int):
	direction = dir
	# Opcional: Voltear el sprite de la bala para que mire a la dirección correcta
	if $Sprite2D: # Cambia $Sprite2D al nombre de tu nodo de sprite
		$Sprite2D.flip_h = direction < 0

func _on_body_entered(body):
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
