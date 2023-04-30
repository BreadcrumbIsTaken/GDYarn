@tool
class_name YarnImporter
extends EditorImportPlugin

const YARN_TRACKER_PATH := "res://.tracked_yarn_files"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


func _get_importer_name():
	return "gdyarn.yarnFile"


func _get_visible_name():
	return "Yarn Files"


func _get_recognized_extensions():
	return ["yarn"]


func _get_save_extension():
	return "tres"


func _get_resource_type():
	return "Resource"


enum Presets { Default }


func _get_preset_count():
	return 1


func _get_import_options(path, preset):
	return []


func _get_preset_name(preset):
	for key in Presets.keys():
		if Presets[key] == preset:
			return key
	return "Unknown"


func _get_option_visibility(path, option, options):
	return true

func _get_import_order() -> int:
	return 0

func _import(source_file, save_path, options, platform_variants, gen_files):
	print("imported -> " + source_file)

	var trackedFilesList := PackedStringArray([])
	if FileAccess.file_exists(YARN_TRACKER_PATH):
		var t = FileAccess.open(YARN_TRACKER_PATH, FileAccess.READ)
		trackedFilesList = t.get_as_text().split("\n")
		t.close()
	
	if source_file not in trackedFilesList:
		trackedFilesList.append(source_file)

	var indexesToRemove := []
	for i in range(trackedFilesList.size()):
		if !FileAccess.file_exists(trackedFilesList[i]):
			indexesToRemove.append(i)

	for i in indexesToRemove:
		trackedFilesList.remove_at(i)

	var trackerFile = FileAccess.open(YARN_TRACKER_PATH, FileAccess.WRITE)
	trackerFile.store_string("\n".join(trackedFilesList))
	trackerFile.close()

	var saveFilePath = "%s.%s" % [save_path, _get_save_extension()]
	if FileAccess.file_exists(saveFilePath):
		return OK

	var yarnFile = Resource.new()
	yarnFile.resource_path = source_file
	yarnFile.resource_name = source_file.get_file()

	return ResourceSaver.save(yarnFile, saveFilePath)
