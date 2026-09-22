extends Node

signal room_ready(room_code:String, seed:int, world_name:String, host:bool)
signal failed(message:String)

const RemotePlayer=preload("res://scripts/remote_player.gd")

var game:Node
var socket:=WebSocketPeer.new()
var pending:Dictionary={}
var pending_sent:=false
var active:=false
var room_code:=""
var local_id:=""
var host:=false
var remote_players:Dictionary={}
var send_timer:=0.0

func websocket_url() -> String:
	if OS.has_feature("web"):
		var protocol=str(JavaScriptBridge.eval("window.location.protocol"))
		var hostname=str(JavaScriptBridge.eval("window.location.host"))
		return ("wss://" if protocol=="https:" else "ws://")+hostname+"/ws"
	return "ws://127.0.0.1:8080/ws"

func create_room(player_name:String,seed:int,world_name:String) -> void:
	_begin({"type":"create","name":player_name,"seed":seed,"world_name":world_name})

func join_room(player_name:String,code:String) -> void:
	_begin({"type":"join","name":player_name,"room":code.strip_edges().to_upper()})

func _begin(payload:Dictionary) -> void:
	disconnect_room(false)
	pending=payload
	pending_sent=false
	socket=WebSocketPeer.new()
	var err=socket.connect_to_url(websocket_url())
	if err!=OK:
		failed.emit("Não foi possível conectar ao servidor multiplayer.")

func disconnect_room(notify_game:bool=true) -> void:
	active=false
	room_code=""
	local_id=""
	pending={}
	pending_sent=false
	for id in remote_players.keys():
		if is_instance_valid(remote_players[id]):
			remote_players[id].queue_free()
	remote_players.clear()
	if socket.get_ready_state() in [WebSocketPeer.STATE_OPEN,WebSocketPeer.STATE_CONNECTING]:
		socket.close()
	if notify_game and is_instance_valid(game) and game.has_method("on_multiplayer_disconnected"):
		game.on_multiplayer_disconnected()

func send_json(data:Dictionary) -> void:
	if socket.get_ready_state()==WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(data))

func send_block_change(cell:Vector2i,id:int) -> void:
	if active:
		send_json({"type":"block","x":cell.x,"y":cell.y,"id":id})

func _process(delta:float) -> void:
	socket.poll()
	var state=socket.get_ready_state()
	if state==WebSocketPeer.STATE_OPEN and not pending_sent and not pending.is_empty():
		send_json(pending)
		pending_sent=true
	elif state==WebSocketPeer.STATE_CLOSED and (not pending.is_empty() or active):
		var was_active=active
		active=false
		pending={}
		if was_active:
			failed.emit("A conexão multiplayer foi encerrada.")

	while socket.get_available_packet_count()>0:
		var text=socket.get_packet().get_string_from_utf8()
		var data=JSON.parse_string(text)
		if typeof(data)==TYPE_DICTIONARY:
			_handle(data)

	if active and is_instance_valid(game) and game.active and is_instance_valid(game.player):
		send_timer-=delta
		if send_timer<=0:
			send_timer=0.08
			var anim="idle"
			if is_instance_valid(game.player.sprite):
				anim=str(game.player.sprite.animation)
			send_json({
				"type":"state",
				"x":game.player.position.x,
				"y":game.player.position.y,
				"face":game.player.face,
				"anim":anim
			})

func _handle(data:Dictionary) -> void:
	var type=str(data.get("type",""))
	if type=="error":
		pending={}
		failed.emit(str(data.get("message","Erro multiplayer.")))
		return
	if type=="room":
		active=true
		pending={}
		local_id=str(data.get("id",""))
		room_code=str(data.get("room",""))
		host=bool(data.get("host",false))
		if is_instance_valid(game):
			game.start_multiplayer_session(int(data.get("seed",0)),str(data.get("world_name","Reino Online")),host)
		for p in data.get("players",[]):
			_spawn_remote(p)
		if is_instance_valid(game) and is_instance_valid(game.world):
			for block in data.get("blocks",[]):
				game.apply_online_block(Vector2i(int(block.get("x",0)),int(block.get("y",0))),int(block.get("id",0)))
		room_ready.emit(room_code,int(data.get("seed",0)),str(data.get("world_name","Reino Online")),host)
		return
	if type=="join":
		_spawn_remote(data.get("player",{}))
	elif type=="leave":
		var id=str(data.get("id",""))
		if remote_players.has(id):
			if is_instance_valid(remote_players[id]):
				remote_players[id].queue_free()
			remote_players.erase(id)
	elif type=="state":
		var id=str(data.get("id",""))
		if id==local_id:
			return
		if not remote_players.has(id):
			_spawn_remote(data)
		if remote_players.has(id):
			remote_players[id].set_state(Vector2(float(data.get("x",0)),float(data.get("y",0))),int(data.get("face",1)),str(data.get("anim","idle")))
	elif type=="block":
		if is_instance_valid(game):
			game.apply_online_block(Vector2i(int(data.get("x",0)),int(data.get("y",0))),int(data.get("id",0)))

func _spawn_remote(data:Dictionary) -> void:
	if not is_instance_valid(game):
		return
	var id=str(data.get("id",""))
	if id=="" or id==local_id:
		return
	if remote_players.has(id):
		return
	var remote=RemotePlayer.new()
	remote.setup(str(data.get("name","Jogador")),Vector2(float(data.get("x",400)),float(data.get("y",1000))),int(data.get("face",1)),str(data.get("anim","idle")))
	game.add_child(remote)
	remote_players[id]=remote
