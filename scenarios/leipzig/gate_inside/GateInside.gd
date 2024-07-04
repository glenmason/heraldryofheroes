extends TextureRect

@onready var fade_player: AnimationPlayer = get_node("FadePanel/FadePlayer")
@onready var text_player: AnimationPlayer = get_node("TextBox/TextPlayer")
@onready var audio_player: AnimationPlayer = get_node("Audio/AudioPlayer")
@onready var is_text_faded_in = true
@onready var next_scene = null

func _ready():
	Data.time = 1
	Data.stats["location"] = "leipzig/gate_inside/GateInside"
	Data.save_game()
	$Audio.play()
	audio_player.play("fade_in_music")
	$TextBox/Time.text = "It is " + Data.get_bell_time()
	fade_in_scenery()
	await fade_player.animation_finished
	is_text_faded_in = false

# Buttons

func _on_gate_outside_pressed():
	$TextBox/Outcome.text = "You return to the Latin Quarter."
	next_scene = "res://scenarios/leipzig/gate_outside/GateOutside.tscn"
	scene_outcome()
	
func _on_gate_outside_sneak_pressed():
	$TextBox/Outcome.text = "You successful evade the attention of the guards as you sneak through the gates."
	next_scene = "res://scenarios/leipzig/gate_outside/GateOutside.tscn"
	scene_outcome()
	
func _on_city_wall_pressed():
	$TextBox/Outcome.text = "You follow the walls to an area that is more secluded."
	next_scene = "res://scenarios/leipzig/city_wall/CityWall.tscn"
	scene_outcome()
	
func _on_main_st_pressed():
	$TextBox/Outcome.text = "You return to the main street."
	next_scene = "res://scenarios/leipzig/main_st/MainSt.tscn"
	scene_outcome()

func scene_outcome():
	$TextBox/Outcome.visible = true
	audio_player.play("fade_out_music")
	var options : Array = $TextBox/Options.get_children()
	for i in options.size():
		options[i].disabled = true
		options[i].mouse_filter = MOUSE_FILTER_IGNORE

# Click to reveal scenario text
func _unhandled_input(event):
	if (event is InputEventMouseButton or InputEventKey) and event.is_pressed():
		get_viewport().set_input_as_handled()
		if is_text_faded_in == false:
			fade_in_text()
			is_text_faded_in = true
		elif next_scene != null:
			Main.goto_scene(next_scene)

# Fade in and out functions for scene changes.
func fade_in_scenery():
	$FadePanel.visible = true
	if Data.time > 6 and Data.time < 18:
		texture = load("res://scenarios/leipzig/gate_inside/GateInside.jpg")
		fade_player.play("fade_in_light")
	else:
		texture = load("res://scenarios/leipzig/gate_inside/GateInside.jpg")
		fade_player.play("fade_in_dark")
	
func fade_in_text():
	$TextBox.visible = true
	$TextBox/Options/GateOutside.grab_focus()
	if Data.time > 6 and Data.time < 18:
		fade_player.play("fade_out_light")
		text_player.play("fade_in_text_dark")
	else:
		fade_player.play("fade_out_dark")
		text_player.play("fade_in_text_light")

