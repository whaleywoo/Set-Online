extends Control

enum {PLAYER_1, PLAYER_2, PLAYER_3, PLAYER_4, PLAYER_5, PLAYER_6}

# Board States
enum {NEUTRAL, PLAYER_DECLARED_SET, OPPONENT_DECLARED_SET, PLAYER_DECLARED_NO_SET,
OPPONENT_DECLARED_NO_SET, PLAYER_DISPLAYING_VALID_SET_RESULT, PLAYER_DISPLAYING_INVALID_SET_RESULT,
OPPONENT_DISPLAYING_VALID_SET_RESULT, OPPONENT_DISPLAYING_INVALID_SET_RESULT, GAME_OVER}

const CARD_VERTICAL_OFFSET = 120
const CARD_HORIZONTAL_OFFSET = 80
const LOGO_CARD_ROTATION = 30
const LOGO_CARD_OFFSET = Vector2(20, -10)
const DECLARED_SET_WAIT_TIME = 6
const NO_SET_WAIT_TIME = 16
const SET_RESULT_WAIT_TIME = 1
const MAX_CARD_COUNT = 21
const BOARD_CARDS_INITIAL_X_POSITION = 360

onready var card_scene := preload("res://Scenes/Card.tscn")

onready var set_button = $SetButton
onready var no_set_button = $NoSetButton
onready var board_cards = $Cards
onready var logo_cards = $LogoCards
onready var timer = $TimerPanel/Timer
onready var timer_label = $TimerPanel/TimerLabel
onready var notification_label = $NotificationLabel
onready var game_over_panel = $GameOverPanel
onready var number_labels = $GameOverPanel/NumberLabels
onready var name_labels = $GameOverPanel/NameLabels

onready var player_1_name_label = $PointLabels/Player1/Name
onready var player_2_name_label = $PointLabels/Player2/Name
onready var player_3_name_label = $PointLabels/Player3/Name
onready var player_4_name_label = $PointLabels/Player4/Name
onready var player_5_name_label = $PointLabels/Player5/Name
onready var player_6_name_label = $PointLabels/Player6/Name

onready var player_1_score_label = $PointLabels/Player1/Score
onready var player_2_score_label = $PointLabels/Player2/Score
onready var player_3_score_label = $PointLabels/Player3/Score
onready var player_4_score_label = $PointLabels/Player4/Score
onready var player_5_score_label = $PointLabels/Player5/Score
onready var player_6_score_label = $PointLabels/Player6/Score

onready var player_1_labels = $PointLabels/Player1
onready var player_2_labels = $PointLabels/Player2
onready var player_3_labels = $PointLabels/Player3
onready var player_4_labels = $PointLabels/Player4
onready var player_5_labels = $PointLabels/Player5
onready var player_6_labels = $PointLabels/Player6

var player := 0

var card_positions = []

var cards_remaining = []

var guessed_cards = []

var state = 0

var scores = [0, 0, 0, 0, 0, 0]

# Players who have declared no set so far
var declared_no_set_players = []

signal entered_state(state)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	initialize_card_positions()
	if (get_tree().is_network_server()):
		player = PLAYER_1
	else:
		player = PLAYER_2
	if player == PLAYER_1:
		initialize_deck()
		make_logo_cards()
		fill_board()
#	initialize_deck()
#	make_logo_cards()
#	fill_board()


func on_game_started() -> void:
	for role in Gamestate.roles:
		if Gamestate.roles[role] == PLAYER_1:
			player_1_name_label.text = Gamestate.players[role]
			player_1_labels.visible = true
		elif Gamestate.roles[role] == PLAYER_2:
			player_2_name_label.text = Gamestate.players[role]
			player_2_labels.visible = true
		elif Gamestate.roles[role] == PLAYER_3:
			player_3_name_label.text = Gamestate.players[role]
			player_3_labels.visible = true
		elif Gamestate.roles[role] == PLAYER_4:
			player_4_name_label.text = Gamestate.players[role]
			player_4_labels.visible = true
		elif Gamestate.roles[role] == PLAYER_5:
			player_5_name_label.text = Gamestate.players[role]
			player_5_labels.visible = true
		elif Gamestate.roles[role] == PLAYER_6:
			player_6_name_label.text = Gamestate.players[role]
			player_6_labels.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not timer.is_stopped() and not state in [PLAYER_DISPLAYING_VALID_SET_RESULT, \
	PLAYER_DISPLAYING_INVALID_SET_RESULT, OPPONENT_DISPLAYING_VALID_SET_RESULT, \
	OPPONENT_DISPLAYING_INVALID_SET_RESULT]:
		timer_label.text = str(floor(timer.time_left))
	else:
		timer_label.text = ""

# Resets the deck to 81 unique cards
func initialize_deck() -> void:
	cards_remaining = []
	var logo_card_attributes = []
	for logo_card in logo_cards.get_children():
		logo_card_attributes.append(logo_card.attributes)
	for i in range(3):
		for j in range(3):
			for k in range(3):
				for l in range(3):
					if not [i, j, k, l] in logo_card_attributes:
						cards_remaining.append([i, j, k, l])
	cards_remaining.shuffle()

# Resets card positions
func initialize_card_positions() -> void:
	card_positions = []
	for i in range(5):
		for j in range(3):
			var new_position = Vector2(i*CARD_HORIZONTAL_OFFSET, j*CARD_VERTICAL_OFFSET)
			card_positions.append(new_position)
	for i in range(3):
		var new_position = Vector2(-CARD_HORIZONTAL_OFFSET, i*CARD_VERTICAL_OFFSET)
		card_positions.append(new_position)
	for i in range(3):
		var new_position = Vector2(5*CARD_HORIZONTAL_OFFSET, i*CARD_VERTICAL_OFFSET)
		card_positions.append(new_position)

# Fills the board based on its current card count
remote func fill_board() -> void:
	if board_cards.get_child_count() < 12:
		while board_cards.get_child_count() < 12 and cards_remaining:
			add_card("board")
		no_set_button.disabled = false
	elif board_cards.get_child_count() < 15:
		while board_cards.get_child_count() < 15 and cards_remaining:
			add_card("board")
		no_set_button.disabled = false
	elif board_cards.get_child_count() < 18:
		while board_cards.get_child_count() < 18 and cards_remaining:
			add_card("board")
		no_set_button.disabled = false
	elif board_cards.get_child_count() < 21:
		while board_cards.get_child_count() < 21 and cards_remaining:
			add_card("board")
		no_set_button.disabled = true
	organize_cards()
	var board_card_attributes = []
	for board_card in board_cards.get_children():
		board_card_attributes.append(board_card.attributes)
	rpc("update_board", board_card_attributes)

# Adds a single card to the board
func add_card(destination) -> void:
	var new_card = card_scene.instance()
	connect("entered_state", new_card, "_on_board_entered_state")
	new_card.connect("card_clicked", self, "_on_card_clicked")
	new_card.attributes = cards_remaining[0]
	cards_remaining.remove(0)
	if destination == "board":
		board_cards.add_child(new_card)
	else:
		logo_cards.add_child(new_card)

# Neatly moves all the cards on the board
func organize_cards() -> void:
	for i in range(board_cards.get_child_count()):
		board_cards.get_child(i).rect_position = card_positions[i]
	if board_cards.get_child_count() > 18:
		board_cards.rect_position.x = BOARD_CARDS_INITIAL_X_POSITION - .5*CARD_HORIZONTAL_OFFSET
	else:
		board_cards.rect_position.x = BOARD_CARDS_INITIAL_X_POSITION


remote func update_board(board_card_attributes) -> void:
	for board_card in board_cards.get_children():
		board_card.free()
	for attribute_set in board_card_attributes:
		var new_card = card_scene.instance()
		connect("entered_state", new_card, "_on_board_entered_state")
		new_card.connect("card_clicked", self, "_on_card_clicked")
		new_card.attributes = attribute_set
		board_cards.add_child(new_card)
	if board_cards.get_child_count() >= MAX_CARD_COUNT:
		no_set_button.disabled = true
	else:
		no_set_button.disabled = false
	organize_cards()

# Adds cards to the logo
func make_logo_cards() -> void:
	for i in range(3):
		add_card("logo")
	var logo_card_attributes = []
	for logo_card in logo_cards.get_children():
		logo_card_attributes.append(logo_card.attributes)
	rpc("set_logo_cards", logo_card_attributes)
	for i in range(3):
		logo_cards.get_child(i).rect_rotation += LOGO_CARD_ROTATION*(i-1)
		logo_cards.get_child(i).rect_position += LOGO_CARD_OFFSET*i
		logo_cards.get_child(i).make_back_card(i)

# Adds given cards to the logo
remote func set_logo_cards(logo_card_attributes) -> void:
	for attribute_set in logo_card_attributes:
		var new_card = card_scene.instance()
		connect("entered_state", new_card, "_on_board_entered_state")
		new_card.connect("card_clicked", self, "_on_card_clicked")
		new_card.attributes = attribute_set
		logo_cards.add_child(new_card)
	for i in range(3):
		logo_cards.get_child(i).rect_rotation += LOGO_CARD_ROTATION*(i-1)
		logo_cards.get_child(i).rect_position += LOGO_CARD_OFFSET*i
		logo_cards.get_child(i).make_back_card(i)

# Moves logo cards based on how many are left
func update_logo_cards() -> void:
	if logo_cards.get_child_count() == 2:
		logo_cards.get_child(0).make_back_card(1)
		logo_cards.get_child(1).make_front_card()
	elif logo_cards.get_child_count() == 1:
		logo_cards.get_child(0).make_front_card()

# Removes a card from the logo
remote func remove_logo_card() -> void:
	logo_cards.get_child(logo_cards.get_child_count()-1).free()
	update_logo_cards()

# Triggered when a player clicks a card
# If the player has clicked at least 3 cards, it checks for a set
func _on_card_clicked(clicked_card) -> void:
	guessed_cards.append(clicked_card)
	# Make it glow for other players
	rpc("make_card_glow", clicked_card.attributes)
	if len(guessed_cards) >= 3:
		set_timer_all(SET_RESULT_WAIT_TIME)
		
		if check_for_set():
			display_set_result(true)
			update_scores(Gamestate.role, 1)
			rpc("update_scores", Gamestate.role, 1)
			change_state(PLAYER_DISPLAYING_VALID_SET_RESULT)
			rpc("change_state", OPPONENT_DISPLAYING_VALID_SET_RESULT)
		else:
			display_set_result(false)
			update_scores(Gamestate.role, -1)
			rpc("update_scores", Gamestate.role, -1)
			change_state(PLAYER_DISPLAYING_INVALID_SET_RESULT)
			rpc("change_state", OPPONENT_DISPLAYING_INVALID_SET_RESULT)

# Sets the timer for all players
func set_timer_all(time_constant):
	set_timer(time_constant)
	rpc("set_timer", time_constant)

# Sets the timer for a single player
remote func set_timer(time_constant):
	timer.wait_time = time_constant
	timer.start()

# Stops the timer for all players
func stop_timer_all():
	stop_timer()
	rpc("stop_timer")

# Stops the timer for a single player
remote func stop_timer():
	timer.stop()

# Communicates whether a player correctly guessed a set
remote func display_set_result(result):
	if result:
		notification_label.text = "It's a SET!"
	else:
		notification_label.text = "No SET!"

# Checks to see if the cards a player clicked are in a set
func check_for_set() -> bool:
	for i in range(4):
		if (guessed_cards[0].attributes[i] == guessed_cards[1].attributes[i] and \
		guessed_cards[1].attributes[i] != guessed_cards[2].attributes[i] and \
		guessed_cards[2].attributes[i] != guessed_cards[0].attributes[i]) or \
		(guessed_cards[0].attributes[i] != guessed_cards[1].attributes[i] and \
		guessed_cards[1].attributes[i] == guessed_cards[2].attributes[i] and \
		guessed_cards[2].attributes[i] != guessed_cards[0].attributes[i]) or \
		(guessed_cards[0].attributes[i] != guessed_cards[1].attributes[i] and \
		guessed_cards[1].attributes[i] != guessed_cards[2].attributes[i] and \
		guessed_cards[2].attributes[i] == guessed_cards[0].attributes[i]):
			return false
	return true

# Changes state and takes the necessary steps in response to the state change
remote func change_state(new_state, enable_no_set_button=true) -> void:
	state = new_state
	emit_signal("entered_state", state)
	if state == NEUTRAL:
		game_over_panel.visible = false
		notification_label.text = ""
		for guessed_card in guessed_cards:
			guessed_card.color_rect.modulate = Color(1, 1, 1, 1)
		guessed_cards = []
		set_button.disabled = false
		if board_cards.get_child_count() < MAX_CARD_COUNT:
			if enable_no_set_button:
				no_set_button.disabled = false
		for card in board_cards.get_children() + logo_cards.get_children():
			card.unglow()
	elif state == PLAYER_DECLARED_SET:
		notification_label.text = "You declared SET!"
		rpc("change_state", OPPONENT_DECLARED_SET)
	elif state == PLAYER_DECLARED_NO_SET:
		notification_label.text = "You declared No SET!"
		rpc("change_state", OPPONENT_DECLARED_NO_SET)
	elif state == OPPONENT_DECLARED_SET:
		notification_label.text = "Opponent declared SET!"
		set_button.disabled = true
		no_set_button.disabled = true
		timer.wait_time = DECLARED_SET_WAIT_TIME
		timer.start()
	elif state == OPPONENT_DECLARED_NO_SET:
		notification_label.text = "Opponent declared No SET!"
		timer.wait_time = NO_SET_WAIT_TIME
		timer.start()
	elif state == OPPONENT_DISPLAYING_VALID_SET_RESULT:
		pass
		display_set_result(true)
	elif state == OPPONENT_DISPLAYING_INVALID_SET_RESULT:
		pass
		display_set_result(false)
	elif state == GAME_OVER:
		for card in board_cards.get_children():
			card.free()
		set_button.disabled = true
		no_set_button.disabled = true
		game_over_panel.visible = true
		var names = []
		var used_scores = []
		for i in range(len(Gamestate.roles)):
			for role in Gamestate.roles:
				if Gamestate.roles[role] == i:
					names.append(Gamestate.players[role])
			used_scores.append(scores[i])
		var score_sorted_names = []
		for i in range(len(Gamestate.roles)):
			var max_index = used_scores.find(used_scores.max())
			score_sorted_names.append(names[max_index])
			names.remove(max_index)
			used_scores.remove(max_index)
		for i in range(len(Gamestate.roles)):
			number_labels.get_child(i).visible = true
			name_labels.get_child(i).visible = true
			name_labels.get_child(i).text = score_sorted_names[i]

# Makes a clicked card glow
remote func make_card_glow(card_attributes) -> void:
	for card in board_cards.get_children() + logo_cards.get_children():
		if card.attributes == card_attributes:
			card.glow()

# Updates a player's score
remote func update_scores(player_role, score_change) -> void:
	scores[player_role] += score_change
	update_score_labels()

# Resets all the scores to 0
remote func reset_scores() -> void:
	scores = [0, 0, 0, 0, 0, 0]

# Makes the score labels display the correct scores
remote func update_score_labels() -> void:
	player_1_score_label.text = str(scores[PLAYER_1])
	player_2_score_label.text = str(scores[PLAYER_2])
	player_3_score_label.text = str(scores[PLAYER_3])
	player_4_score_label.text = str(scores[PLAYER_4])
	player_5_score_label.text = str(scores[PLAYER_5])
	player_6_score_label.text = str(scores[PLAYER_6])

# Declares a set, allowing the declaring player to choose cards
func _on_SetButton_pressed() -> void:
	declared_no_set_players = []
	rpc("update_declared_no_set_players", null)
	set_button.disabled = true
	no_set_button.disabled = true
	change_state(PLAYER_DECLARED_SET)
	timer.wait_time = DECLARED_SET_WAIT_TIME
	timer.start()

# Declares "no set", setting a timer to add new cards
func _on_NoSetButton_pressed() -> void:
	if state == NEUTRAL:
		no_set_button.disabled = true
		change_state(PLAYER_DECLARED_NO_SET)
		timer.wait_time = NO_SET_WAIT_TIME
		timer.start()
		declared_no_set_players.append(Gamestate.role)
		rpc("update_declared_no_set_players", Gamestate.role)
	elif state == OPPONENT_DECLARED_NO_SET:
		no_set_button.disabled = true
		declared_no_set_players.append(Gamestate.role)
		rpc("update_declared_no_set_players", Gamestate.role)
		if len(declared_no_set_players) >= len(Gamestate.players):
			end_no_set()

# Brings players back to neutral board state after "no set" declaration ends
func end_no_set() -> void:
	declared_no_set_players = []
	rpc("update_declared_no_set_players", null)
	stop_timer_all()
	change_state(NEUTRAL, false)
	rpc("change_state", NEUTRAL, false)
	if Gamestate.role == PLAYER_1:
		player_1_end_no_set()
	else:
		rpc_id(1, "player_1_end_no_set")

# Fills everyone's boards with new cards
remote func player_1_end_no_set() -> void:
	if cards_remaining:
		fill_board()
	else:
		end_game()

# Adds a player to the list of no set players or resets the list
remote func update_declared_no_set_players(which_player) -> void:
	if which_player == null:
		declared_no_set_players = []
	else:
		declared_no_set_players.append(which_player)

# Sets the state to GAME_OVER
func end_game() -> void:
	change_state(GAME_OVER)
	rpc("change_state", GAME_OVER)

# Resets the game to play again
remote func reset_game() -> void:
	reset_scores()
	update_score_labels()
	rpc("reset_scores")
	rpc("update_score_labels")
	for card in board_cards.get_children():
		card.free()
	initialize_deck()
	fill_board()
	change_state(NEUTRAL)
	rpc("change_state", NEUTRAL)

# Enacts the timeout conditions based on the current state
func _on_Timer_timeout() -> void:
	if state == PLAYER_DISPLAYING_VALID_SET_RESULT:
		var guessed_card_attributes = []
		for guessed_card in guessed_cards:
			guessed_card_attributes.append(guessed_card.attributes)
		guessed_cards = []
		if Gamestate.role == PLAYER_1:
			remove_cards(guessed_card_attributes)
		else:
			rpc_id(1, "remove_cards", guessed_card_attributes)
		change_state(NEUTRAL)
		rpc("change_state", NEUTRAL)
	elif state == PLAYER_DISPLAYING_INVALID_SET_RESULT:
		change_state(NEUTRAL)
		rpc("change_state", NEUTRAL)
	elif state == PLAYER_DECLARED_SET:
		update_scores(Gamestate.role, -1)
		rpc("update_scores", Gamestate.role, -1)
		change_state(PLAYER_DISPLAYING_INVALID_SET_RESULT)
		rpc("change_state", OPPONENT_DISPLAYING_INVALID_SET_RESULT)
		set_timer_all(SET_RESULT_WAIT_TIME)
		display_set_result(false)
	elif state == PLAYER_DECLARED_NO_SET:
		end_no_set()

# Removes the guessed cards when a set was found
remote func remove_cards(guessed_card_attributes) -> void:
	var original_logo_card_count = logo_cards.get_child_count()
	for card in board_cards.get_children() + logo_cards.get_children():
		if card.attributes in guessed_card_attributes:
			card.free()
	update_logo_cards()
	if logo_cards.get_child_count() < original_logo_card_count:
		rpc("remove_logo_card")
	if board_cards.get_child_count() < 12:
		fill_board()
	else:
		organize_cards()
		var board_card_attributes = []
		for board_card in board_cards.get_children():
			board_card_attributes.append(board_card.attributes)
		rpc("update_board", board_card_attributes)

# Resets the game after a player pressed the play again button
func _on_PlayAgainButton_pressed() -> void:
	if Gamestate.role == PLAYER_1:
		reset_game()
	else:
		rpc_id(1, "reset_game")
