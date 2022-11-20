extends Node

# Players
enum {PLAYER_1, PLAYER_2, PLAYER_3, PLAYER_4, PLAYER_5, PLAYER_6}

# Default game port
const DEFAULT_PORT = 10318

# Max number of players
const MAX_PEERS = 6

# Name for my player
var player_name = "Player"

# Names for remote players in id:name format
var players = {}

# Players ready to start the game
var players_ready = []

# Roles for all players in id:role format
var roles = {}

# Our role
var role = -1

# Iterate through this when assigning roles
var role_index = 1

# Emits when game is started
signal game_started

# Signals to let lobby GUI know what's going on
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)


func _ready():
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")


# Callback from SceneTree
func _player_disconnected(id):
	if (get_tree().is_network_server()):
		if (has_node("/root/Scenes/Board")): # Game is in progress
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			end_game()
		else: # Game is not in progress
			# If we are the server, send to the new dude all the already registered players
			unregister_player(id)
			for p_id in players:
				# Erase in the server
				if p_id != get_tree().get_network_unique_id():
					rpc_id(p_id, "unregister_player", id)


# Callback from SceneTree, only for clients (not server)
func _connected_ok():
	# Registration of a client beings here, tell everyone that we are here
	rpc("register_player", get_tree().get_network_unique_id(), player_name)
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server)
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server)
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

# Lobby management functions

remote func register_player(id, new_player_name):
	if (get_tree().is_network_server()):
		# If we are the server, let client know about self
		rpc_id(id, "register_player", 1, player_name) # Send myself to new player
		# Send new player to other players
		for player_id in players:
			rpc_id(id, "register_player", player_id, players[player_id]) # Send myself to new player
			rpc_id(player_id, "register_player", get_tree().get_rpc_sender_id(), new_player_name)

	players[id] = new_player_name
	emit_signal("player_list_changed")


remote func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")


remote func pre_start_game():
	# Change scene
	var board = load("res://Scenes/Board.tscn").instance()
	connect("game_started", board, "on_game_started")
	get_tree().get_root().add_child(board)

	get_tree().get_root().get_node("Lobby").hide()

	if (not get_tree().is_network_server()):
		# Tell server we are ready to start
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()


remote func post_start_game():
	players[get_tree().get_network_unique_id()] = player_name
	emit_signal("game_started")
	get_tree().set_pause(false) # Unpause and start the game


remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if (not id in players_ready):
		players_ready.append(id)

	if (players_ready.size() == players.size()):
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()

func host_game(new_player_name):
	player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)

func join_game(ip, new_player_name):
	player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)

func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func begin_game():
	assert(get_tree().is_network_server())
	role = PLAYER_1
	roles[1] = PLAYER_1
	for p in players:
		rpc_id(p, "pre_start_game")
		roles[p] = role_index
		role_index += 1
	role_index = 1
	rpc("update_all_roles", roles)
	
	pre_start_game()

func end_game():
	if (has_node("/root/Scenes/Board")): # Game is in progress
		# End it
		get_node("/root/Scenes/Board").queue_free()

	emit_signal("game_ended")
	players.clear()
	get_tree().set_network_peer(null) # End networking


remote func update_all_roles(new_roles):
	roles = new_roles
	role = new_roles[get_tree().get_network_unique_id()]
