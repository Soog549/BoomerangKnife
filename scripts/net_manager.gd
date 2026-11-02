extends Node
## NetManager — LAN/прямое подключение (ENet). Хост-авторитет.

const PORT := 7777
const MAX_PLAYERS := 22

signal players_changed(players: Array)
signal connection_state(text: String)
signal hosts_changed(hosts: Array)
const BEACON_PORT := 7778

var players: Dictionary = {}
var found_hosts: Dictionary = {}
var _beacon: PacketPeerUDP = null
var _listen: PacketPeerUDP = null
var _beacon_t := 0.0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_left)
	players[1] = {"name": "ХОСТ"}


func _process(dt: float) -> void:
	_beacon_t += dt
	if _beacon != null and _beacon_t >= 2.0:
		_beacon_t = 0.0
		_beacon.set_dest_address("255.255.255.255", BEACON_PORT)
		_beacon.put_packet(("BK_HOST:%d" % PORT).to_utf8_buffer())
	if _listen != null:
		while _listen.get_available_packet_count() > 0:
			var pkt := _listen.get_packet()
			var ip := _listen.get_packet_ip()
			var txt := pkt.get_string_from_utf8()
			if txt.begins_with("BK_HOST:"):
				found_hosts[ip] = Time.get_unix_time_from_system()
				hosts_changed.emit(known_hosts())


func hosts_changed_signal() -> void:
	hosts_changed.emit(known_hosts())


func known_hosts() -> Array:
	var now := Time.get_unix_time_from_system()
	var out: Array = []
	for ip in found_hosts.keys():
		if now - float(found_hosts[ip]) < 8.0:
			out.append(str(ip))
	return out


func start_discovery() -> void:
	if _listen == null:
		_listen = PacketPeerUDP.new()
		_listen.bind(BEACON_PORT, "0.0.0.0")
		_listen.set_broadcast_enabled(true)


func stop_discovery() -> void:
	if _listen != null:
		_listen.close()
		_listen = null
	found_hosts.clear()


func host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		connection_state.emit("Не удалось поднять сервер (порт %d)" % PORT)
		return
	multiplayer.multiplayer_peer = peer
	if _beacon == null:
		_beacon = PacketPeerUDP.new()
		_beacon.set_broadcast_enabled(true)
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
	if _beacon != null:
		_beacon.close()
		_beacon = null
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
