extends Node

#consts
const DEFAULT_START: String = "Start"

#classes

# const StandardLibrary = preload("res://addons/gdyarn/core/libraries/standard.gd")
const YarnProgram = preload("res://addons/gdyarn/core/program/program.gd")
const VirtualMachine = preload("res://addons/gdyarn/core/virtual_machine.gd")
# const YarnLibrary = preload("res://addons/gdyarn/core/library.gd")

var library
var executionComplete: bool

var _variableStorage

var _debugLog: Callable
var _errLog: Callable

var _program: YarnProgram

var _vm: VirtualMachine

var _visitedNodeCount: Dictionary = {}


func _init(variableStorage):
	_variableStorage = variableStorage
	_vm = VirtualMachine.new(self)
	var YarnLibrary = load("res://addons/gdyarn/core/library.gd")
	# var _variableStorage
	library = YarnLibrary.new()
	_debugLog = dlog
	_errLog = elog
	executionComplete = false

	# import the standard library
	# this contains math constants, operations and checks
	var StandardLibrary = load("res://addons/gdyarn/core/libraries/standard.gd")
	library.import_library(StandardLibrary.new())  #FIX

	# add a function to lib that checks if node is visited
	library.register_function("visited", -1, is_node_visited, true)

	# add function to lib that gets the node visit count
	library.register_function("visit_count", -1, node_visit_count, true)

	# add function to lib that gets a random number from 0-1
	library.register_function("random", 0, random, true)

	# add function to lib that gets a random integers from a range
	library.register_function("random_range", 2, random_range, true)

	# add function to lib that gets a random floats from a range
	library.register_function("random_rangef", 2, random_rangef, true)

	# add function to lib that gets a random number from 1-sides
	library.register_function("dice", 1, dice, true)

	# add function to lib that rounds to the nearest integer
	library.register_function("round", 1, _round, true)

	# add function to lib that rounds to the nearest integer
	library.register_function("round_places", 2, round_places, true)

	# add function to lib that rounds down
	library.register_function("floor", 1, _floor, true)

	# add function to lib that rounds up
	library.register_function("ceil", 1, _ceil, true)

	# add function to lib that rounds up to the nearest integer. if n is already an integer, inc returns n+1.
	library.register_function("inc", 1, inc, true)

	# add function to lib that rounds down to the nearest integer. if n is already an integer, dec returns n-1.
	library.register_function("dec", 1, dec, true)

	# add function to lib that returns the decimal.
	library.register_function("decimal", 1, decimal, true)

	# add function to lib that rounds down to the nearest integer towards zero
	library.register_function("int", 1, _int, true)


func dlog(message: String):
	print("YARN_DEBUG : %s" % message)


func elog(message: String):
	printerr("YARN_ERROR : %s" % message)


func is_active() -> bool:
	return get_exec_state() != YarnGlobals.ExecutionState.Stopped


#gets the current execution state of the virtual machine
func get_exec_state():
	return _vm.executionState


func set_selected_option(option: int):
	_vm.set_selected_option(option)


func set_node(name: String = DEFAULT_START):
	_vm.set_node(name)


func resume():
	if _vm.executionState == YarnGlobals.ExecutionState.Running:
		return
	_vm.resume()


func stop():
	_vm.stop()
	pass


func get_all_nodes() -> Array:
	return _program.yarnNodes.keys()


func current_node() -> String:
	return _vm.get_current()


func get_node_id(name: String) -> String:
	if _program.nodes.size() == 0:
		_errLog.call("No nodes loaded")
		return ""
	if _program.nodes.has(name):
		return "id:" + name
	else:
		_errLog.call("No node named [%s] exists" % name)
		return ""


func get_program_strings() -> Dictionary:
	return _program.yarnStrings


func unloadAll(clear_visited: bool = true):
	if clear_visited:
		_visitedNodeCount.clear()
	_program = null


func dump() -> String:
	return _program.dump(library)


func node_exists(name: String) -> bool:
	return _program.nodes.has(name)


func set_program(program):
	_program = program
	_vm.set_program(_program)
	_vm.reset()


func get_program():
	return _program


func add_program(program):
	if _program == null:
		set_program(program)
	else:
		_program = YarnGlobals.combine_programs([_program, program])


func analyze(context):
	print(": not implemented")
	pass


func get_vm() -> VirtualMachine:
	return _vm


func is_node_visited(node: String = _vm.current_node_name()) -> bool:
	return node_visit_count(node) > 0


func node_visit_count(node: String = _vm.current_node_name()) -> int:
	var visitCount: int = 0
	if _visitedNodeCount.has(node):
		visitCount = _visitedNodeCount[node]
	return visitCount


func get_visited_nodes():
	return _visitedNodeCount.keys()


func set_visited_nodes(visitedList):
	_visitedNodeCount.clear()
	for string in visitedList:
		_visitedNodeCount[string] = 1


func random() -> float:
	var rng = RandomNumberGenerator.new()
	return rng.randf_range(0.0, 1.0)


func random_range(a: Value, b: Value) -> int:
	var rng = RandomNumberGenerator.new()
	return rng.randi_range(a.number, b.number)


func random_rangef(a: Value, b: Value) -> float:
	var rng = RandomNumberGenerator.new()
	return rng.randf_range(a.number, b.number)


func dice(sides: Value) -> int:
	var rng = RandomNumberGenerator.new()
	return rng.randi_range(1, sides.number)


func _round(n: Value) -> int:
	return roundi(n.number)


func round_places(n: Value, places: Value) -> float:
	return snappedf(n.number, places.number)


func _floor(n: Value) -> int:
	return floori(n.number)


func _ceil(n: Value) -> int:
	return ceili(n.number)


func inc(n: Value) -> int:
	if n.number == int(n.number):
		return n.number + 1
	else:
		return ceili(n.number)


func dec(n: Value) -> int:
	if n.number == int(n.number):
		return n.number - 1
	else:
		return floori(n.number)


func decimal(n: Value) -> float:
	if n.number > 0:
		return n.number - int(n.number)
	else:
		return int(n.number) - n.number


func _int(n: Value) -> int:
	return int(n.number)
