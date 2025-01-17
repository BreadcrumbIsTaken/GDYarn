extends Label

var strings: PackedStringArray = []

@onready var storage = get_node("../VariableStorage")


func _ready():
	if storage == null:
		printerr("Variable Storage is null!")


func _process(_delta):
	strings.resize(0)
	strings.append("Stored Variables:\n")
	for key in storage.var_names():
		strings.append("\t%s : %s \n" % [key, storage.get_value(key)])
	text = "".join(strings)
