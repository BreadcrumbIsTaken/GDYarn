extends Object

var command: String
var args: Array


func _init(input: String):
	var result = input.strip_edges().split(" ")
	self.command = result[0]

	if result.size() > 1:
		result.remove_at(0)
		args = result
