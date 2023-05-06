extends EditorInspectorPlugin

var compilerUi: PackedScene = preload("res://addons/gdyarn/ui/CompileUi.tscn")


func _can_handle(object):
	if object.has_method("_handle_command"):
		return true
	return false


func _parse_begin(object):
	var instance = compilerUi.instantiate()
	# if !instance.is_connected("compile_clicked", Callable(object, "_compile_programs")):
	# 	instance.connect("compile_clicked", Callable(object, "_compile_programs"))
	instance.compile_clicked.connect(object._compile_programs)

	add_custom_control(instance)
