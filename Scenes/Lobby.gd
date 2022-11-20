extends Control

onready var connect_node = $Connect
onready var players_node = $Players

func _ready():
	# Called every time the node is added to the scene.
	Gamestate.connect("connection_failed", self, "_on_connection_failed")
	Gamestate.connect("connection_succeeded", self, "_on_connection_success")
	Gamestate.connect("player_list_changed", self, "refresh_lobby")
	Gamestate.connect("game_ended", self, "_on_game_ended")
	Gamestate.connect("game_error", self, "_on_game_error")

func _on_Host_pressed():
	if (connect_node.get_node("NameField").text == ""):
		connect_node.get_node("ErrorLabel").text="Invalid name!"
		return

	connect_node.hide()
	players_node.show()
	connect_node.get_node("ErrorLabel").text=""

	var player_name = connect_node.get_node("NameField").text
	Gamestate.host_game(player_name)
	refresh_lobby()

func _on_Join_pressed():
	if (connect_node.get_node("NameField").text == ""):
		connect_node.get_node("ErrorLabel").text="Invalid name!"
		return

	var ip = connect_node.get_node("IPField").text
	if (not ip.is_valid_ip_address()):
		connect_node.get_node("ErrorLabel").text="Invalid IPv4 address!"
		return

	connect_node.get_node("ErrorLabel").text=""
	connect_node.get_node("Host").disabled=true
	connect_node.get_node("Join").disabled=true

	var player_name = connect_node.get_node("NameField").text
	Gamestate.join_game(ip, player_name)
	# refresh_lobby() gets called by the player_list_changed signal

func _on_connection_success():
	connect_node.hide()
	players_node.show()

func _on_connection_failed():
	connect_node.get_node("Host").disabled=false
	connect_node.get_node("Join").disabled=false
	connect_node.get_node("ErrorLabel").set_text("Connection failed.")

func _on_game_ended():
	show()
	connect_node.show()
	players_node.hide()
	connect_node.get_node("Host").disabled=false
	connect_node.get_node("Join").disabled=false

func _on_game_error(errtxt):
	get_node("ErrorPopup").dialog_text = errtxt
	get_node("ErrorPopup").popup_centered_minsize()

# updates player list and disables start button for clients
func refresh_lobby():
	var players = Gamestate.get_player_list()
	players.sort()
	players_node.get_node("ItemList").clear()
	players_node.get_node("ItemList").add_item(Gamestate.get_player_name() + " (You)")
	for p in players:
		players_node.get_node("ItemList").add_item(p)

	players_node.get_node("Start").disabled=not get_tree().is_network_server()


func _on_Start_pressed():
	Gamestate.begin_game()
