extends Node

# Esta es tu "mochila". Estas variables nunca se borrarán al cambiar de nivel.
var vidas : int = 3
var monedas : int = 0

# Variable para recordar en qué nivel murió el jugador
var nivel_actual_path : String = "" 

# Función para reiniciar todo cuando sea Game Over
func reset_datos():
	vidas = 3
	monedas = 0
