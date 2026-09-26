extends RefCounted

const PATH="user://dreads_multiplayer_history.json"
const BACKUP_PATH="user://dreads_multiplayer_history.json.bak"
const VERSION=1
const MAX_EVENTS=250

static func _read() -> Dictionary:
	for path in [PATH,BACKUP_PATH]:
		if not FileAccess.file_exists(path):
			continue
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and int(parsed.get("version",0))==VERSION:
			return parsed
	return {"version":VERSION,"accounts":{}}

static func _write(data:Dictionary) -> Error:
	var user_dir=ProjectSettings.globalize_path("user://")
	var dir_error=DirAccess.make_dir_recursive_absolute(user_dir)
	if dir_error!=OK:
		return dir_error
	var abs_path=ProjectSettings.globalize_path(PATH)
	var abs_bak=ProjectSettings.globalize_path(BACKUP_PATH)
	if FileAccess.file_exists(PATH):
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.remove_absolute(abs_bak)
		DirAccess.copy_absolute(abs_path,abs_bak)
	var file=FileAccess.open(PATH,FileAccess.WRITE)
	if file==null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	return OK

static func record(account:String,event_type:String,room:String,world_name:String,player_name:String,player_id:String="") -> Error:
	var owner=account.strip_edges().to_lower()
	if owner=="" or event_type not in ["join","leave"]:
		return ERR_INVALID_PARAMETER
	var data=_read()
	var accounts:Dictionary=data.get("accounts",{})
	var entries:Array=accounts.get(owner,[])
	entries.append({
		"event":event_type,
		"player":player_name.strip_edges().left(24),
		"player_id":player_id.left(40),
		"room":room.strip_edges().to_upper().left(8),
		"world":world_name.strip_edges().left(40),
		"date":Time.get_date_string_from_system(),
		"time":Time.get_time_string_from_system(),
		"timestamp":int(Time.get_unix_time_from_system())
	})
	while entries.size()>MAX_EVENTS:
		entries.pop_front()
	accounts[owner]=entries
	data["accounts"]=accounts
	return _write(data)

static func list_for(account:String) -> Array:
	var owner=account.strip_edges().to_lower()
	if owner=="":
		return []
	var data=_read()
	var accounts:Dictionary=data.get("accounts",{})
	var result=accounts.get(owner,[])
	return result.duplicate(true) if result is Array else []
