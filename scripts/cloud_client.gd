extends Node

const PROD_URL="https://dreads-craft-v13-production-42b9.up.railway.app"
var token:=""
var username:=""

func is_enabled() -> bool:
	return OS.has_feature("web") or OS.has_feature("android")

func is_authenticated() -> bool:
	return token!=""

func clear_session() -> void:
	token=""
	username=""

func _origin() -> String:
	if OS.has_feature("web"):
		var value=JavaScriptBridge.eval("window.location.origin",true)
		if value!=null and str(value).begins_with("http"):
			return str(value)
	return PROD_URL

func _request_json(method:int,path:String,payload:Dictionary={}) -> Dictionary:
	var request=HTTPRequest.new()
	request.timeout=18.0
	add_child(request)
	var headers=PackedStringArray(["Content-Type: application/json","Accept: application/json"])
	if token!="":
		headers.append("Authorization: Bearer "+token)
	var body="" if payload.is_empty() else JSON.stringify(payload)
	var start_error=request.request(_origin()+path,headers,method,body)
	if start_error!=OK:
		request.queue_free()
		return {"ok":false,"status":0,"message":"Não foi possível conectar ao servidor."}
	var response=await request.request_completed
	request.queue_free()
	var result_code=int(response[0])
	var status=int(response[1])
	var raw:PackedByteArray=response[3]
	if result_code!=HTTPRequest.RESULT_SUCCESS:
		return {"ok":false,"status":0,"message":"Conexão com o servidor falhou."}
	var parsed=JSON.parse_string(raw.get_string_from_utf8())
	if not parsed is Dictionary:
		return {"ok":false,"status":status,"message":"Resposta inválida do servidor."}
	parsed["status"]=status
	return parsed

func create_account(user:String,password:String) -> Dictionary:
	var result=await _request_json(HTTPClient.METHOD_POST,"/api/account/create",{"username":user,"password":password})
	if bool(result.get("ok",false)):
		token=str(result.get("token",""))
		username=str(result.get("user",""))
	return result

func login(user:String,password:String) -> Dictionary:
	var result=await _request_json(HTTPClient.METHOD_POST,"/api/account/login",{"username":user,"password":password})
	if bool(result.get("ok",false)):
		token=str(result.get("token",""))
		username=str(result.get("user",""))
	return result

func list_worlds() -> Dictionary:
	return await _request_json(HTTPClient.METHOD_GET,"/api/worlds")

func load_world(world_id:String) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_GET,"/api/worlds/"+world_id.uri_encode())

func save_world(world_id:String,data:Dictionary) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_PUT,"/api/worlds/"+world_id.uri_encode(),{"data":data})

func delete_world(world_id:String) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_DELETE,"/api/worlds/"+world_id.uri_encode())
