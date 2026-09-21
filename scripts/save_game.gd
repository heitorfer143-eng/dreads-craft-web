extends RefCounted

const PATH = "user://dreads_world.json"
const INDEX_PATH = "user://dreads_worlds.json"
const WORLDS_DIR = "user://worlds"
static var active_id := ""

static func _safe_id(name: String) -> String:
	var clean=name.to_lower().strip_edges().replace(" ","_")
	for ch in ["/","\\",":","*","?","\"","<",">","|"]:
		clean=clean.replace(ch,"")
	return clean.left(36)+"_"+str(abs(name.hash()))

static func list_worlds() -> Array:
	var result=[]
	if FileAccess.file_exists(INDEX_PATH):
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
		if parsed is Array:
			result=parsed
	if result.is_empty() and FileAccess.file_exists(PATH):
		var legacy=read_path(PATH)
		if not legacy.is_empty():
			var id=_safe_id(str(legacy.get("name","Reino do Abismo")))
			active_id=id
			write(legacy)
			result=_read_index()
	return result

static func _read_index() -> Array:
	if not FileAccess.file_exists(INDEX_PATH):
		return []
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
	return parsed if parsed is Array else []

static func _write_index(entries: Array) -> void:
	var f=FileAccess.open(INDEX_PATH,FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(entries))
		f.close()

static func select_world(id: String) -> void:
	active_id=id

static func write(data: Dictionary) -> Error:
	var directory_error=DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(WORLDS_DIR))
	if directory_error!=OK:
		return directory_error
	if active_id.is_empty():
		active_id=_safe_id(str(data.get("name","Reino do Abismo")))
	var save_path=WORLDS_DIR+"/"+active_id+".json"
	if directory_error!=OK:
		return directory_error
	var file=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file==null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.close()
	if FileAccess.file_exists(save_path):
		var backup_error=DirAccess.copy_absolute(save_path,save_path+".bak")
		if backup_error!=OK:
			return backup_error
	var rename_error=DirAccess.rename_absolute(save_path+".tmp",save_path)
	if rename_error!=OK:
		return rename_error
	var entries=_read_index()
	var meta={"id":active_id,"name":str(data.get("name","Reino")),"day":int(data.get("day",1)),"clock":float(data.get("clock",0.32)),"creative":bool(data.get("creative",false)),"difficulty":int(data.get("difficulty",1)),"saved_at":int(data.get("saved_at",0))}
	var replaced=false
	for i in entries.size():
		if str(entries[i].get("id",""))==active_id:
			entries[i]=meta
			replaced=true
	if not replaced:
		entries.push_front(meta)
	_write_index(entries)
	return OK

static func read_path(save_path: String) -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(save_path))
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

static func read_save() -> Dictionary:
	if active_id.is_empty():
		var worlds=list_worlds()
		if worlds.is_empty(): return {}
		active_id=str(worlds[0].get("id",""))
	return read_path(WORLDS_DIR+"/"+active_id+".json")

static func erase_save() -> Error:
	var save_path=WORLDS_DIR+"/"+active_id+".json"
	if FileAccess.file_exists(save_path):
		var error=DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		if error!=OK:
			return error
	if FileAccess.file_exists(save_path+".bak"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+".bak"))
	var entries=_read_index().filter(func(e): return str(e.get("id",""))!=active_id)
	_write_index(entries)
	active_id=""
	return OK
