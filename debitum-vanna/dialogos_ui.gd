# En 'dialogos_ui.gd'
extends CanvasLayer
signal dialogo_terminado

@onready var texto_label = $Panel/RichTextLabel
@onready var caja_dialogo = $Panel

var lineas_dialogo: Array[String] = []
var linea_actual = 0

func _ready():
	caja_dialogo.hide()
	
func _input(_event):
	if caja_dialogo.visible and _event.is_action_pressed("interact") and not _event.is_echo():
		mostrar_siguiente_linea()
		get_viewport().set_input_as_handled()

func iniciar(lineas: Array[String]):
	if lineas.is_empty():
		return
		
	lineas_dialogo = lineas
	linea_actual = 0
	caja_dialogo.show()
	texto_label.text = lineas_dialogo[linea_actual]

func mostrar_siguiente_linea():
	linea_actual += 1
	if linea_actual < lineas_dialogo.size():
		texto_label.text = lineas_dialogo[linea_actual]
	else:
		lineas_dialogo = []
		linea_actual = 0
		caja_dialogo.hide()
		
		print("DEBUG DialogosUi: Diálogo terminado. ¡EMITIENDO SEÑAL!")
		dialogo_terminado.emit()

func is_dialogo_activo():
	return caja_dialogo.visible
