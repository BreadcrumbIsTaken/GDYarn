extends HBoxContainer

signal clicked

var wasPressed: bool = false


func _ready():
	var _ok = connect("gui_input", on_gui_input)


func on_gui_input(input):
	if input is InputEventMouseButton:
		var mouseEvent = input as InputEventMouseButton
		if mouseEvent.pressed:
			wasPressed = true
		elif wasPressed:
			wasPressed = false
			clicked.emit()
