extends Node
## NetManager — LAN/прямое подключение (ENet). Хост-авторитет.

const PORT := 7777
const MAX_PLAYERS := 22

signal players_changed(players: Array)
signal connection_state(text: String)

var players: Dictionary = {}


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_left)
	players[1] = {"name": "ХОСТ"}


func host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		connection_state.emit("Не удалось поднять сервер (порт %d)" % PORT)
		return
	multiplayer.multiplayer_peer = peer
	players = {1: {"name": "ХОСТ"}}
	connection_state.emit("Хост: порт %d, игроков: 1" % PORT)
	players_changed.emit(_list())


func join(ip: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		connection_state.emit("Ошибка подключения к %s" % ip)
		return
	multiplayer.multiplayer_peer = peer
	connection_state.emit("Подключаемся к %s:%d..." % [ip, PORT])


func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	players.clear()
	connection_state.emit("Отключено")
	players_changed.emit([])


func _list() -> Array:
	var out: Array = []
	for id in players.keys():
		out.append({"id": int(id), "name": str(players[id].get("name", "Игрок"))})
	return out


@rpc("any_peer", "call_remote", "reliable")
func register_name(nm: String) -> void:
	var id := multiplayer.get_remote_sender_id()
	players[id] = {"name": nm}
	players_changed.emit(_list())
	rpc("sync_players", players)


@rpc("authority", "call_remote", "reliable")
func sync_players(data: Dictionary) -> void:
	players = data
	players_changed.emit(_list())


func _on_peer_connected(id: int) -> void:
	players[id] = {"name": "Игрок %d" % id}
	connection_state.emit("Подключился игрок %d" % id)
	players_changed.emit(_list())


func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	connection_state.emit("Отключился игрок %d" % id)
	players_changed.emit(_list())


func _on_connected() -> void:
	connection_state.emit("Подключено к хосту")
	rpc_id(1, "register_name", "Игрок")


func _on_failed() -> void:
	connection_state.emit("Не удалось подключиться")


func _on_server_left() -> void:
	connection_state.emit("Хост отключился")
	players.clear()
	players_changed.emit([])
