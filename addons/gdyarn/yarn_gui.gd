@icon("res://addons/gdyarn/assets/display.svg")
extends Control

### TODO: Add interpolation to different aspects of this ui
###        * when ui is shown
###        * when ui is hidden
###        * when options are shown
###        * when options are hidden
###
### This is the default yarn display implementation that comes bundles out of the box
### for GDYarn. You are able to create your own if you need to but for general game development
### and prototyping purposes it should be enough.
class_name YarnDisplay

# emit this signal every time the text changes
signal text_changed

# emit this signal when a new line has started to display
signal line_started

# emit this signal when a new line has finished displaying
signal line_finished

#emit this signal when options have begun to be shown
signal options_shown

# emit this signal once an option
# has been selected
signal option_selected

# signal emitted when `show_gui` has been called
signal gui_shown

# signal emitted when `hide_gui` has been called
signal gui_hidden

@export var _yarnRunner: NodePath
@export var _text: NodePath
@export var _namePlate: NodePath
@export var _options: Array[NodePath]:
	set = set_option_nodes

# controls the rate at which the text is displayed
@export var _textSpeed: int = 1

# just holds variables I dont want too exposed to the outside.
var config: Configuration = Configuration.new()

var yarnRunner
var text
var namePlate
var options: Array

# the next line queued up to be displayed.
var nextLine: String = ""

# used to check if the current line is finished being displayed
var lineFinished: bool = true
var elapsedTime: float = 0
var totalLineTime: float = 1
var showingOptions: bool = false
var shouldContinue: bool = true
var isDialogueFinished: bool = false

var shouldUpdateTotalLineTime: bool = false

var nameRegex: RegEx

var lastVisibleChars: int = 0


func _ready():
	nameRegex = RegEx.new()
	nameRegex.compile("^(?:.*(?=:))")
	if _namePlate:
		namePlate = get_node(_namePlate)
		if !namePlate.has_method("set_text"):
			namePlate = null

	if _yarnRunner:
		yarnRunner = get_node(_yarnRunner)
		yarnRunner.connect("line_emitted", set_line)
		yarnRunner.connect("node_started", on_node_start)
		yarnRunner.connect("options_emitted", show_options)
		yarnRunner.connect("dialogue_finished", on_dialogue_finished)
		yarnRunner.connect("command_emitted", on_command)

	if _text:
		text = get_node(_text)
		if text is RichTextLabel:
			config.richTextLabel = true
		elif text is Label:
			pass
		elif text && !text.has_method("set_text"):
			config.unknownOutput = true
	else:
		config.unknownOutput = true
	for option in _options:
		options.push_back(get_node(option))
		if options.back().has_signal("pressed"):
			options.back().connect("pressed", select_option.bind(options.size() - 1))

	hide_options()


func _process(delta):
	if shouldUpdateTotalLineTime:
		shouldUpdateTotalLineTime = false
		totalLineTime = float(text.get_total_character_count()) / float(_textSpeed)

	if !lineFinished && !config.unknownOutput:
		if _textSpeed <= 0 || elapsedTime >= totalLineTime:
			lineFinished = true
			elapsedTime += totalLineTime
			line_finished.emit()
			yarnRunner.resume()

	if totalLineTime > 0:
		text.visible_ratio = elapsedTime / totalLineTime
		if lastVisibleChars != text.visible_characters:
			text_changed.emit()
		lastVisibleChars = text.visible_characters
	else:
		text.visible_characters = 1.0

	elapsedTime += delta
	pass


func on_dialogue_finished():
	isDialogueFinished = true


func on_command(command, arguments: Array):
	if command == "wait":
		clear_text()
		line_started.emit()


## make the yarn gui visible and emit the gui shown signal
func show_gui():
	gui_shown.emit()
	self.visible = true
	isDialogueFinished = false
	lineFinished = false


## hide the yarn gui and emit the gui hidden signal
## NOTE: not calling this can break certain things if they are
## 		 depengint on the gui_hidden signal from the yarn gui.
func hide_gui():
	gui_hidden.emit()
	self.visible = false


## set the next line to be displayed
## if the current line is is_empty then immediately display the next line
func set_line(line: String):
	if config.unknownOutput:
		return

	var result: RegExMatch = nameRegex.search(line)

	if namePlate:
		if result:
			var name: String = result.get_string()
			line = line.replace(name + ":", "")
			set_name_plate(name)
		else:
			namePlate.visible = false

	nextLine = line
	if shouldContinue:
		shouldContinue = false
		display_next_line()


func set_name_plate(name: String):
	namePlate.set_text(name)
	namePlate.visible = true


## display the next line to the text label provided.
## this sets lineFinished to false, and empties the contents
## of nextLine into currentLine
func display_next_line():
	lineFinished = false
	if !config.unknownOutput && !nextLine.is_empty():
		# TODO add some preprocessing if we have a name plate available and the line contains
		#      a string in the format "name: content"
		if config.richTextLabel:
			lastVisibleChars = 0
			(text as RichTextLabel).visible_characters = 0
			text.parse_bbcode(nextLine)
		else:
			text.set_text(nextLine)

		shouldUpdateTotalLineTime = true
		text_changed.emit()
		line_started.emit()
		elapsedTime = 0
		nextLine = ""


## finish the current line, and if it is already
## displaying the current line then resume the dialogue
## which will feed us another line
func finish_line():
	if showingOptions:
		return

	if isDialogueFinished:
		hide_gui()
		return

	if lineFinished:
		if nextLine.is_empty():
			shouldContinue = true
			yarnRunner.resume()
		elif !nextLine.is_empty():
			display_next_line()
	else:
		lineFinished = true
		elapsedTime += totalLineTime
		yarnRunner.resume()


## do this when a new node starts
## to get the dialogue rolling
func on_node_start(nodeName):
	yarnRunner.resume()


func hide_options():
	for option in options:
		option.visible = false
	showingOptions = false


## display the optionlines to the user
## by using the options that we set in the inspector
## if we have less options in the display than the
## supplied optionlines then we will simply ignore the exra
## options lines, but we will still display an error
## to the user as this might be unwanted behavior.
func show_options(optionLines):
	if self.options.size() < optionLines.size():
		printerr(
			(
				"Received [%d] options, but only have[%d] option nodes in yarn_gui."
				% [optionLines.size(), options.size()]
			)
		)

	for i in range(min(options.size(), optionLines.size())):
		options[i].set_text(optionLines[i])
		options[i].visible = true

	showingOptions = true
	options_shown.emit()


## If we are currently showing options on the display
## then we may make a selection.
func select_option(option):
	yarnRunner.choose(option)
	hide_options()
	clear_text()
	shouldContinue = true
	finish_line()
	option_selected.emit()


func set_runner_node(runner):
	if get_node(runner) && !get_node(runner).has_signal("line_emitted"):
		return
	_yarnRunner = runner


func set_text_node(node):
	_text = node


func set_option_nodes(nodes):
	_options = nodes


func clear_text():
	if text:
		text.clear()
	if namePlate:
		namePlate.visible = false


class Configuration:
	# if this is a rich text label then we are going to use
	# bb text by default , if we change this again at runtime
	# then we will no longer use bb text
	var richTextLabel: bool = false

	# if an output is unknown we will expect it to contain
	# a set_text(text) function and if it does not then we
	# want to print out an error to the console instead letting the user
	# know that the output form is invalid.
	var unknownOutput: bool = false
