extends TextureRect

@onready var is_text_faded_in = true
var next_scene = null
var winter = false
var night = false

func _ready():
	if Data.time["month"] > 2 and Data.time["month"] < 12:
		winter = false
		if Data.time["hour"] > 6 and Data.time["hour"] < 18:
			night = false
		else:
			night = true
	else:
		winter = true
		if Data.time["hour"] > 8 and Data.time["hour"] < 16:
			night = false
		else:
			night = true
	$TextBox/Time.text = "It is " + Data.get_bell_time()
	
	Data.get_node("Party").dict["location"] = "res://scenarios/leipzig/gate_inside/gate_inside.tscn"
	Data.save_game()
	
	Main.get_node("Audio/SFX").stream = load("res://audio/sfx/group_walking.ogg")
	Main.get_node("Audio/SFX").playing = true
	Main.get_node("Audio/SFX/Player").play("fade_in")
	fade_in_scenery()
	await $FadePanel/Player.animation_finished
	is_text_faded_in = false

# Buttons
func _on_gate_outside_pressed():
	$TextBox/Outcome.text = "You return to the Latin Quarter."
	next_scene = "res://scenarios/leipzig/gate_outside/gate_outside.tscn"
	scene_outcome()
	
func _on_gate_outside_sneak_pressed():
	$TextBox/Outcome.text = "You successful evade the attention of the guards as you sneak through the gates."
	next_scene = "res://scenarios/leipzig/gate_outside/gate_outside.tscn"
	scene_outcome()
	
func _on_city_wall_pressed():
	$TextBox/Outcome.text = "You follow the walls to an area that is more secluded."
	next_scene = "res://scenarios/leipzig/city_wall/city_wall.tscn"
	scene_outcome()
	
func _on_main_st_pressed():
	$TextBox/Outcome.text = "You return to the main street."
	next_scene = "res://scenarios/leipzig/main_st/main_st.tscn"
	scene_outcome()

func scene_outcome():
	Main.get_node("Audio/SFX/Player").play("fade_out")
	$TextBox/Outcome.visible = true
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
	if winter:
		if night:
			texture = load("res://scenarios/leipzig/gate_inside/gate_inside_wn.jpg")
			$FadePanel/Player.play("fade_in_dark")
		else:
			texture = load("res://scenarios/leipzig/gate_inside/gate_inside_wd.jpg")
			$FadePanel/Player.play("fade_in_light")
	else:
		if night:
			texture = load("res://scenarios/leipzig/gate_inside/gate_inside_sn.jpg")
			$FadePanel/Player.play("fade_in_dark")
		else:
			texture = load("res://scenarios/leipzig/gate_inside/gate_inside_sd.jpg")
			$FadePanel/Player.play("fade_in_light")
	
func fade_in_text():
	$TextBox.visible = true
	$TextBox/Options.get_child(0).grab_focus()
	if winter:
		if night:
			$FadePanel/Player.play("fade_out_dark")
			$TextBox/Player.play("fade_in_text_light")
		else:
			$FadePanel/Player.play("fade_out_light")
			$TextBox/Player.play("fade_in_text_dark")
	else:
		if night:
			$FadePanel/Player.play("fade_out_dark")
			$TextBox/Player.play("fade_in_text_light")
		else:
			$FadePanel/Player.play("fade_out_light")
			$TextBox/Player.play("fade_in_text_dark")

