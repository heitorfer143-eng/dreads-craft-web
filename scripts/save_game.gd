extends RefCounted

const PATH = "user://dreads_world.json"
const INDEX_PATH = "user://dreads_worlds.json"
const WORLDS_DIR = "user://worlds"
const SAVE_VERSION = 11
const VALID_BLOCK_IDS = [0,1,2,3,4,5,6,7,8,9,14,15,16,25,28,29,30,31]
const MIN_WORLD_WIDTH = 320
const MAX_WORLD_WIDTH = 8192
static var active_id := ""
static var active_account := ""

static func _safe_id(name: String) -> String:
	var clean=name.to_lower().strip_edges().replace(" ","_")
	for ch in ["/","\\",":","*","?","\"","<",">","|"]:
		clean=clean.replace(ch,"")
	return clean.left(36)+"_"+str(abs(name.hash()))

static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path)

static func set_account(username:String) -> void:
	active_account=username.strip_edges().to_lower()
	active_id=""
	_claim_legacy_worlds()

static func clear_account() -> void:
	active_account=""
	active_id=""

static func _claim_legacy_worlds() -> void:
	if active_account=="":
		return
	var entries=_read_index()
	var owns_any=false
	for entry in entries:
		if str(entry.get("owner",""))==active_account:
			owns_any=true
			break
	if owns_any:
		return
	var changed=false
	for i in entries.size():
		if str(entries[i].get("owner",""))=="":
			entries[i]["owner"]=active_account
			changed=true
	if changed:
		_write_index(entries)

static func list_worlds() -> Array:
	# Always use the validated index reader so a damaged primary index can recover
	# from the automatic .bak/.tmp copies instead of making all worlds look missing.
	if active_account=="":
		return []
	_claim_legacy_worlds()
	var result=_read_index().filter(func(e): return str(e.get("owner",""))==active_account)
	if result.is_empty() and FileAccess.file_exists(PATH):
		var legacy=read_path(PATH)
		if not legacy.is_empty():
			var id=_safe_id(str(legacy.get("name","Reino do Abismo")))
			active_id=id
			write(legacy)
			result=_read_index()
	return result

static func _read_index() -> Array:
	for path in [INDEX_PATH,INDEX_PATH+".bak",INDEX_PATH+".tmp"]:
		if not FileAccess.file_exists(path):
			continue
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Array:
			return parsed
	return []

static func _write_index(entries: Array) -> void:
	var tmp=INDEX_PATH+".tmp"
	var f=FileAccess.open(tmp,FileAccess.WRITE)
	if not f:
		return
	f.store_string(JSON.stringify(entries))
	f.flush()
	f.close()
	var index_abs=_abs(INDEX_PATH)
	var tmp_abs=_abs(tmp)
	if FileAccess.file_exists(INDEX_PATH):
		var backup_abs=_abs(INDEX_PATH+".bak")
		DirAccess.remove_absolute(backup_abs)
		DirAccess.copy_absolute(index_abs,backup_abs)
		DirAccess.remove_absolute(index_abs)
	DirAccess.rename_absolute(tmp_abs,index_abs)

static func select_world(id: String) -> void:
	active_id=id

static func write(data: Dictionary) -> Error:
	if active_account=="":
		return ERR_INVALID_PARAMETER
	var dir_abs=_abs(WORLDS_DIR)
	var directory_error=DirAccess.make_dir_recursive_absolute(dir_abs)
	if directory_error!=OK:
		return directory_error
	if active_id.is_empty():
		active_id=_safe_id(str(data.get("name","Reino do Abismo")))

	data["version"]=SAVE_VERSION
	data["owner"]=active_account
	var save_path=WORLDS_DIR+"/"+active_id+".json"
	var tmp_path=save_path+".tmp"
	var bak_path=save_path+".bak"
	var save_abs=_abs(save_path)
	var tmp_abs=_abs(tmp_path)
	var bak_abs=_abs(bak_path)

	var file=FileAccess.open(tmp_path,FileAccess.WRITE)
	if file==null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()

	# Save atomically: keep the last valid file as .bak, remove the old
	# destination, then rename the fully-written temporary file.
	if FileAccess.file_exists(save_path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_abs)
		var backup_error=DirAccess.copy_absolute(save_abs,bak_abs)
		if backup_error!=OK:
			DirAccess.remove_absolute(tmp_abs)
			return backup_error
		var remove_error=DirAccess.remove_absolute(save_abs)
		if remove_error!=OK:
			DirAccess.remove_absolute(tmp_abs)
			return remove_error

	var rename_error=DirAccess.rename_absolute(tmp_abs,save_abs)
	if rename_error!=OK:
		# Last-resort restore if replacing an existing save failed.
		if FileAccess.file_exists(bak_path) and not FileAccess.file_exists(save_path):
			DirAccess.copy_absolute(bak_abs,save_abs)
		return rename_error

	var entries=_read_index()
	var meta={
		"id":active_id,
		"name":str(data.get("name","Reino")),
		"seed":int(data.get("seed",1)),
		"day":int(data.get("day",1)),
		"clock":float(data.get("clock",0.32)),
		"creative":bool(data.get("creative",false)),
		"difficulty":int(data.get("difficulty",1)),
		"saved_at":int(data.get("saved_at",0)),
		"owner":active_account
	}
	var replaced=false
	for i in entries.size():
		if str(entries[i].get("id",""))==active_id:
			entries[i]=meta
			replaced=true
			break
	if not replaced:
		entries.push_front(meta)
	_write_index(entries)
	return OK

static func read_path(save_path: String) -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not parsed is Dictionary:
		return {}
	var version=int(parsed.get("version",1))
	if version<1 or version>SAVE_VERSION:
		return {}
	var owner=str(parsed.get("owner",""))
	if active_account!="" and owner!="" and owner!=active_account:
		return {}
	# Forward migration: old worlds keep working after game updates.
	if not parsed.has("hotbar"):
		parsed["hotbar"]=[0,0,0,0,0,0,0,0,0]
	if not parsed.has("selected"):
		parsed["selected"]=0
	if not parsed.has("dropped_items"):
		parsed["dropped_items"]=[]
	if not parsed.has("boss_defeated"):
		parsed["boss_defeated"]=false
	if not parsed.has("in_purity_realm"):
		parsed["in_purity_realm"]=false
	if not parsed.has("quest_states"):
		parsed["quest_states"]={}
	if not parsed.has("snow_reached"):
		parsed["snow_reached"]=false
	if not parsed.has("abyss_slime_kills"):
		parsed["abyss_slime_kills"]=0
	if not parsed.has("abyss_warden_kills"):
		parsed["abyss_warden_kills"]=0
	if not parsed.has("lake_boss_defeated"):
		parsed["lake_boss_defeated"]=false
	if not parsed.has("lake_boss_hp"):
		parsed["lake_boss_hp"]=-1.0
	if not parsed.has("lake_generated"):
		parsed["lake_generated"]=false
	if not parsed.has("lake_center_x"):
		parsed["lake_center_x"]=-1
	if not parsed.has("lake_width"):
		parsed["lake_width"]=-1
	if not parsed.has("lake_depth"):
		parsed["lake_depth"]=-1
	if not parsed.has("lake_water_y"):
		parsed["lake_water_y"]=-1
	if not parsed.has("lake_discovered"):
		parsed["lake_discovered"]=false
	if not parsed.has("in_lake_temple"):
		parsed["in_lake_temple"]=false
	if not parsed.has("forms_unlocked"):
		parsed["forms_unlocked"]={"spike":true,"fox":bool(parsed.get("lake_boss_defeated",false))}
	if not parsed.has("current_form"):
		parsed["current_form"]="spike"
	if not parsed.has("chests"):
		parsed["chests"]={}
	parsed["version"]=SAVE_VERSION
	var cells=parsed.get("cells",[])
	if not cells is Array or cells.size()!=96:
		return {}
	var row_width=-1
	for row in cells:
		if not row is Array:
			return {}
		if row_width<0:
			row_width=row.size()
			if row_width<MIN_WORLD_WIDTH or row_width>MAX_WORLD_WIDTH:
				return {}
		elif row.size()!=row_width:
			return {}
		for id in row:
			if not id is float and not id is int:
				return {}
			if id!=int(id) or int(id) not in VALID_BLOCK_IDS:
				return {}
	var surfaces=parsed.get("surfaces",[])
	if not surfaces is Array or surfaces.size()!=row_width:
		return {}
	for row in cells:
		for x in row.size():
			row[x]=int(row[x])
	return parsed

static func read_save() -> Dictionary:
	if active_id.is_empty():
		var worlds=list_worlds()
		if worlds.is_empty():
			return {}
		active_id=str(worlds[0].get("id",""))
	var save_path=WORLDS_DIR+"/"+active_id+".json"
	var data=read_path(save_path)
	if data.is_empty():
		data=read_path(save_path+".bak")
	return data

static func erase_save() -> Error:
	var save_path=WORLDS_DIR+"/"+active_id+".json"
	for suffix in ["",".bak",".tmp"]:
		var path=save_path+suffix
		if FileAccess.file_exists(path):
			var error=DirAccess.remove_absolute(_abs(path))
			if error!=OK:
				return error
	var entries=_read_index().filter(func(e): return str(e.get("id",""))!=active_id)
	_write_index(entries)
	active_id=""
	return OK
