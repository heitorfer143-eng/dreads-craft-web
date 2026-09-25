extends RefCounted

const PATH="user://dreads_accounts.json"
const BACKUP_PATH="user://dreads_accounts.json.bak"
const VERSION=1
const HASH_ROUNDS=20000
static var active_user:=""

static func _normalize_username(raw:String) -> String:
	var clean=raw.strip_edges().to_lower()
	var out=""
	for ch in clean:
		if ch in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			out+=ch
	return out.left(20)

static func _read() -> Dictionary:
	for path in [PATH,BACKUP_PATH]:
		if not FileAccess.file_exists(path):
			continue
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and int(parsed.get("version",0))==VERSION and parsed.get("users",{}) is Dictionary:
			return parsed
	return {"version":VERSION,"last_user":"","users":{}}

static func _write(data:Dictionary) -> Error:
	var tmp=PATH+".tmp"
	var file=FileAccess.open(tmp,FileAccess.WRITE)
	if file==null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var abs_path=ProjectSettings.globalize_path(PATH)
	var abs_tmp=ProjectSettings.globalize_path(tmp)
	var abs_bak=ProjectSettings.globalize_path(BACKUP_PATH)
	if FileAccess.file_exists(PATH):
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.remove_absolute(abs_bak)
		DirAccess.copy_absolute(abs_path,abs_bak)
		DirAccess.remove_absolute(abs_path)
	return DirAccess.rename_absolute(abs_tmp,abs_path)

static func _hash_password(password:String,salt:String) -> String:
	var digest=(salt+":"+password).to_utf8_buffer()
	var salt_bytes=salt.to_utf8_buffer()
	for _i in HASH_ROUNDS:
		var ctx=HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		ctx.update(digest)
		ctx.update(salt_bytes)
		digest=ctx.finish()
	return digest.hex_encode()

static func _secure_equal(a:String,b:String) -> bool:
	if a.length()!=b.length():
		return false
	var diff=0
	for i in a.length():
		diff|=a.unicode_at(i)^b.unicode_at(i)
	return diff==0

static func create_account(username:String,password:String) -> Dictionary:
	var user=_normalize_username(username)
	if user.length()<3:
		return {"ok":false,"message":"Usuário precisa ter pelo menos 3 caracteres."}
	if password.length()<6:
		return {"ok":false,"message":"Senha precisa ter pelo menos 6 caracteres."}
	var data=_read()
	var users:Dictionary=data.get("users",{})
	if users.has(user):
		return {"ok":false,"message":"Esse usuário já existe."}
	var salt=Crypto.new().generate_random_bytes(16).hex_encode()
	users[user]={
		"salt":salt,
		"password_hash":_hash_password(password,salt),
		"created_at":int(Time.get_unix_time_from_system())
	}
	data["users"]=users
	data["last_user"]=user
	var error=_write(data)
	if error!=OK:
		return {"ok":false,"message":"Não foi possível criar a conta local."}
	active_user=user
	return {"ok":true,"message":"Conta criada.","user":user}

static func authenticate(username:String,password:String) -> Dictionary:
	var user=_normalize_username(username)
	var data=_read()
	var users:Dictionary=data.get("users",{})
	if not users.has(user):
		return {"ok":false,"message":"Usuário ou senha inválidos."}
	var record:Dictionary=users[user]
	var expected=str(record.get("password_hash",""))
	var actual=_hash_password(password,str(record.get("salt","")))
	if expected=="" or not _secure_equal(expected,actual):
		return {"ok":false,"message":"Usuário ou senha inválidos."}
	active_user=user
	data["last_user"]=user
	_write(data)
	return {"ok":true,"message":"Login realizado.","user":user}

static func logout() -> void:
	active_user=""

static func last_user() -> String:
	return str(_read().get("last_user",""))

static func has_accounts() -> bool:
	return not (_read().get("users",{}) as Dictionary).is_empty()
