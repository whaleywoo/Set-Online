extends Control

# Board States
enum {NEUTRAL, PLAYER_DECLARED_SET, OPPONENT_DECLARED_SET, PLAYER_DECLARED_NO_SET,
OPPONENT_DECLARED_NO_SET, DISPLAYING_SET_RESULT}

enum {RED, GREEN, PURPLE}
enum {DIAMOND, OVAL, SQUIGGLE}
enum {ONE, TWO, THREE}
enum {LINE, HALF, SOLID}

const RED_COLOR = "f41f9c"
const GREEN_COLOR = "01a608"
const PURPLE_COLOR = "8000c8"

onready var diamond_line = preload("res://Sprites/Symbols/Diamond_Line.png")
onready var diamond_half = preload("res://Sprites/Symbols/Diamond_Half.png")
onready var diamond_solid = preload("res://Sprites/Symbols/Diamond_Solid.png")
onready var oval_line = preload("res://Sprites/Symbols/Oval_Line.png")
onready var oval_half = preload("res://Sprites/Symbols/Oval_Half.png")
onready var oval_solid = preload("res://Sprites/Symbols/Oval_Solid.png")
onready var squiggle_line = preload("res://Sprites/Symbols/Squiggle_Line.png")
onready var squiggle_half = preload("res://Sprites/Symbols/Squiggle_Half.png")
onready var squiggle_solid = preload("res://Sprites/Symbols/Squiggle_Solid.png")

onready var color_rect = $CardBase
onready var shade_rect = $ShadeRect

var board_state := 0
var attributes = [-1,-1,-1,-1] # Color, shape, count, shading
var back_card := false

var already_chosen := false

signal card_clicked(clicked_card)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	draw_symbols()

# Sets current state to the board state
func _on_board_entered_state(new_state) -> void:
	board_state = new_state

# Draws the symbols on the card based on attributes
func draw_symbols() -> void:
	for i in range(attributes[2] + 1):
		var symbol = TextureRect.new()
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		symbol.rect_scale = Vector2(0.25, 0.25)
		if attributes[0] == RED:
			symbol.modulate = RED_COLOR
		elif attributes[0] == GREEN:
			symbol.modulate = GREEN_COLOR
		elif attributes[0] == PURPLE:
			symbol.modulate = PURPLE_COLOR

		if attributes[1] == DIAMOND:
			if attributes[3] == LINE:
				symbol.texture = diamond_line
			elif attributes[3] == HALF:
				symbol.texture = diamond_half
			elif attributes[3] == SOLID:
				symbol.texture = diamond_solid
		elif attributes[1] == OVAL:
			if attributes[3] == LINE:
				symbol.texture = oval_line
			elif attributes[3] == HALF:
				symbol.texture = oval_half
			elif attributes[3] == SOLID:
				symbol.texture = oval_solid
		elif attributes[1] == SQUIGGLE:
			if attributes[3] == LINE:
				symbol.texture = squiggle_line
			elif attributes[3] == HALF:
				symbol.texture = squiggle_half
			elif attributes[3] == SOLID:
				symbol.texture = squiggle_solid
		
		if attributes[2] == ONE:
			symbol.rect_position.y = 28
		elif attributes[2] == TWO:
			symbol.rect_position.y = 17 + i*24
		elif attributes[2] == THREE:
			symbol.rect_position.y = 2 + i*24
		add_child(symbol)

# Places the card behind all other cards
func make_back_card(depth_factor):
	if depth_factor == 1:
		back_card = true
		shade_rect.visible = true
		shade_rect.color = "44000000"
	elif depth_factor == 0:
		back_card = true
		shade_rect.visible = true
		shade_rect.color = "77000000"

# Places the card in front of all other cards
func make_front_card():
	back_card = false
	shade_rect.visible = false

# When card is clicked, makes the card glow if the player has declared set
func _on_CardBase_gui_input(event: InputEvent) -> void:
	if board_state == PLAYER_DECLARED_SET and not already_chosen:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == BUTTON_LEFT:
				glow()
				emit_signal("card_clicked", self)

# Makes the card glow
func glow():
	color_rect.modulate = Color(0.7, 0.7, 1.4, 1)
	already_chosen = true

# Makes the card stop glowing
func unglow():
	color_rect.modulate = Color(1, 1, 1, 1)
	already_chosen = false
