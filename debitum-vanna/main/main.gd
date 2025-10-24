extends Control

# --- VARIABLES ---
@export var logo_estado_1: Texture2D
@export var logo_estado_2: Texture2D
@export var logo_estado_3: Texture2D

@export var proxima_escena_path: String = "res://menu_inicial/menu.tscn"

# Nuevo: Tiempo que dura cada parte del fade (aparecer y desaparecer)
@export var fade_duration: float = 0.01 

# Referencias a nuestros nodos
@onready var texture_rect = $TextureRect
@onready var timer = $Timer
@onready var audio = $AudioStreamPlayer2D

# --- VARIABLES DE ESTADO ---
var estado_actual = 1
var is_fading = false # <--- NUEVO: Para no cambiar si ya hay un fade

func _ready():
	# 1. Empezamos con el logo base, totalmente visible
	texture_rect.texture = logo_estado_1
	texture_rect.modulate.a = 1.0 # <--- NUEVO: Asegura que sea visible
	
	# 2. Conectamos la señal 'timeout' del Timer
	timer.timeout.connect(_on_timer_timeout)
	
	# 3. Mantenemos tu tiempo de 0.4s. 
	#    (El fade_duration debe ser menor que esto)
	timer.wait_time = 0.4
	
	# 4. Iniciamos el timer
	timer.start()
	
	audio.play()
	
	



# Esta función se llamará CADA VEZ que el timer llegue a 0.4s
func _on_timer_timeout():
	preload("res://menu_inicial/menu.tscn")
	
	# <--- NUEVO: Si ya estamos en un fade, ignoramos este tick
	if is_fading:
		return
		
	# Aumentamos el contador de estado
	estado_actual += 1
	
	if estado_actual == 4:
		# Han pasado 0.4s: Hacemos fade al estado 2
		_fade_to_new_texture(logo_estado_2) # <--- CAMBIADO
	
	elif estado_actual == 6:
		# Hacemos fade al estado 3
		_fade_to_new_texture(logo_estado_3) # <--- CAMBIADO

	elif estado_actual == 15:
		# Han pasado X segundos: Terminamos
		timer.stop() # Detenemos el timer
		
		# <--- CAMBIADO: Hacemos un fade final antes de salir
		_fade_out_and_change_scene()

# -----------------------------------------------------------------
# --- FUNCIONES DE FADE AÑADIDAS ---
# -----------------------------------------------------------------

# Esta es la función que pediste.
# Hará un fade-out, cambiará la textura, y hará un fade-in.
func _fade_to_new_texture(new_texture: Texture2D):
	is_fading = true
	var tween = create_tween()
	
	# 1. Fade out (hacer transparente) el logo actual
	tween.tween_property(texture_rect, "modulate", Color(1, 1, 1, 0), fade_duration)
	
	# 2. Cuando termine el fade out, cambiamos la textura
	tween.tween_callback(func():
		texture_rect.texture = new_texture
	)
	
	# 3. Fade in (hacer visible) el nuevo logo
	tween.tween_property(texture_rect, "modulate", Color(1, 1, 1, 1), fade_duration)

	# 4. Cuando el tween termine, permitimos el siguiente fade
	tween.tween_callback(func():
		is_fading = false
	)

# Esta función se usa al final para desaparecer el logo y cambiar de escena
func _fade_out_and_change_scene():
	is_fading = true
	var tween = create_tween()
	
	# Hacemos que el logo final se desvanezca por completo
	tween.tween_property(texture_rect, "modulate", Color(0.0, 0.0, 0.0, 1.0), fade_duration)
	
	# Cuando el logo haya desaparecido... cambiamos de escena
	tween.tween_callback(func():
		if proxima_escena_path != "":
			get_tree().change_scene_to_file(proxima_escena_path)
		else:
			print("Error: No se especificó 'proxima_escena_path' en el SplashScreen.")
	)
