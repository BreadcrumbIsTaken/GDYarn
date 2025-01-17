@tool
extends VBoxContainer

signal compile_clicked(showTokens, printSyntax)

@export var CompileButton: NodePath
@export var ShowTokens: NodePath
@export var PrintTree: NodePath
@export var TestButton: NodePath
@export var OpenDialog: NodePath
@export var Dialog: NodePath


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node(CompileButton).connect("pressed", _clicked)
	get_node(OpenDialog).connect("pressed", _open_dialog)
	get_node(TestButton).connect("pressed", _close_dialog)
	pass  # Replace with function body.


func _clicked():
	compile_clicked.emit(get_node(ShowTokens).button_pressed, get_node(PrintTree).button_pressed)


func _open_dialog():
	get_node(Dialog).popup_centered()


func _close_dialog():
	(get_node(Dialog) as PopupPanel).hide()
