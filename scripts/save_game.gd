extends RefCounted

const PATH = "user://dreads_world.json"

static func write(data: Dictionary) -> Error:
	var directory_error=DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	if directory_error!=OK:
		return directory_error
	var file=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
	if file==null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.close()
	if FileAccess.file_exists(PATH):
		var backup_error=DirAccess.copy_absolute(PATH,PATH+".bak")
		if backup_error!=OK:
			return backup_error
	return DirAccess.rename_absolute(PATH+".tmp",PATH)

static func read_save() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary or int(parsed.get("version",0)) not in [1,2]:
		return {}
	var cells=parsed.get("cells",[])
	if not cells is Array or cells.size()!=96:
		return {}
	for row in cells:
		if not row is Array or row.size()!=320:
			return {}
		for id in row:
			if not id is float and not id is int:
				return {}
			if id!=int(id) or int(id) not in [0,1,2,3,4,5,6,7,8,9,14,15,16]:
				return {}
	for row in cells:
		for x in row.size():
			row[x]=int(row[x])
	return parsed


static func erase_save() -> Error:
	if FileAccess.file_exists(PATH):
		var error=DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
		if error!=OK:
			return error
	if FileAccess.file_exists(PATH+".bak"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+".bak"))
	return OK
