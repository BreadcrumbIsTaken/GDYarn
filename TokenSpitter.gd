extends Node

const Parser = preload("res://addons/gdyarn/core/compiler/parser.gd")
const Lexer = Parser.Lexer  #preload("res://addons/gdyarn/core/compiler/lexer.gd")

@export_file("*.yarn") var yarnFile


func _ready():
	var testString = "en"

	printerr("testString size = %s" % testString.split("_"))
	var file = FileAccess.open(yarnFile, FileAccess.READ)

	var source = file.get_as_text()

	file.close()

	var headerSep: RegEx = RegEx.new()
	file = headerSep.compile("---(\r\n|\r|\n)")
	var headerProperty: RegEx = RegEx.new()
	file = headerProperty.compile("(?<field>.*): *(?<value>.*)")

	#check for atleast one node start
	if !headerSep.search(source):
		printerr("Error parsing yarn input : No headers found")
		return -1

	var lineNumber: int = 0

	var sourceLines: Array = source.split("\n", true)
	# printerr("source lines %s" % sourceLines.size())
	for i in range(sourceLines.size()):
		sourceLines[i] = sourceLines[i].strip_edges(false, true)

	# print("sourceLines:")
	# for line in sourceLines:
	# 	print(line)

	while lineNumber < sourceLines.size():
		var title: String
		var body: String

		#get title
		while true:
			var line: String = sourceLines[lineNumber]
			# print(sourceLines[lineNumber])
			lineNumber += 1

			if !line.is_empty():
				var result = headerProperty.search(line)
				if result != null:
					var field: String = result.get_string("field")
					var value: String = result.get_string("value")

					if field == "title":
						title = value

			if lineNumber >= sourceLines.size() || sourceLines[lineNumber] == "---":
				break

		lineNumber += 1
		#past header
		var bodyLines: PackedStringArray = []

		while lineNumber < sourceLines.size() && sourceLines[lineNumber] != "===":
			bodyLines.append(sourceLines[lineNumber])
			lineNumber += 1

		lineNumber += 1

		body = "\n".join(bodyLines)
		var lexer = Lexer.new()

		var tokens: Array = lexer.tokenize(body, lineNumber)
		print_tokens(title, tokens)

		var parser = Parser.new(tokens)
		var parserNode = parser.parse_node()
		print(parserNode.tree_string(0))

	pass


static func print_tokens(nodeName: String, tokens: Array = []):
	var list: PackedStringArray = []
	for token in tokens:
		list.append(
			(
				"\t [%14s] %s (%s) l:%s\n"
				% [
					token.lexerState,
					YarnGlobals.token_type_name(token.type),
					token.value,
					token.lineNumber
				]
			)
		)
	print("Node[%s] Tokens:" % nodeName)
	print("".join(list))
