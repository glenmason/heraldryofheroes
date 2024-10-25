extends MarginContainer

@onready var party_data = Data.get_node("Party").dict
@onready var party_inventory = get_node("HBox/PartyFrame/PartyInventory")
@onready var sell_items = get_node("HBox/ShopFrame/VBox/SellItems")
@onready var buy_items = get_node("HBox/ShopFrame/VBox/BuyItems")
@onready var shop_stock = get_node("HBox/Merchant/ShopStock")
@onready var is_text_faded_in = true
var next_scene = null
var cost = 0
var best_trade_skill
var stock_dict : Dictionary = {}
	
# Called when the node enters the scene tree for the first time.
func _ready():
	$HBox/Merchant/TextBox/Time.text = "It is " + Data.get_bell_time()
	Data.get_node("Party").dict["location"] = "res://scenarios/leipzig/general_trader/general_trader.tscn"
	Data.save_game()
	
	Main.get_node("Audio/SFX").stream = load("res://audio/sfx/group_walking.ogg")
	Main.get_node("Audio/SFX").playing = true
	Main.get_node("Audio/SFX/Player").play("fade_in")
	
	fade_in_scenery()
	await $FadePanel/Player.animation_finished
	is_text_faded_in = false
	
	add_to_group("inventories")
	best_trade_skill = Data.get_node("Party").get_party_best("trade")
	#load merchant data into variables
	if not FileAccess.file_exists("user://leipzig_shop.save"):
		return
	var save_file = FileAccess.open("user://leipzig_shop.save", FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue
		stock_dict = json.get_data()

# Buttons
func _on_trade_pressed():
	enter_trade() #makes trade nodes visible
	for i in party_data["inventory"]:
		party_inventory.add_item(party_data["inventory"][i], null, true)
	for i in stock_dict:
		shop_stock.add_item(stock_dict[i], null, true)

func _on_leave_pressed():
	$HBox/Merchant/TextBox/Outcome.text = "You thank the merchant for his time and return to the market."
	next_scene = "res://scenarios/leipzig/market/market.tscn"
	scene_outcome()

func scene_outcome():
	Main.get_node("Audio/SFX/Player").play("fade_out")
	$HBox/Merchant/TextBox/Outcome.visible = true
	var options : Array = $HBox/Merchant/TextBox/Options.get_children()
	for i in options.size():
		options[i].disabled = true
		options[i].mouse_filter = MOUSE_FILTER_IGNORE

func _on_shop_stock_item_activated(index):
	buy_items.add_item(shop_stock.get_item_text(index), null, true)
	cost += get_item_cost(shop_stock, index)
	$HBox/ShopFrame/VBox/Amounts/Cost.text = "Cost " + str(cost) + "$"
	shop_stock.remove_item(index)
	shop_stock.select(index)

func _on_buy_items_item_activated(index):
	shop_stock.add_item(buy_items.get_item_text(index), null, true)
	cost -= get_item_cost(buy_items, index)
	$HBox/ShopFrame/VBox/Amounts/Cost.text = "Cost " + str(cost) + "$"
	buy_items.remove_item(index)
	buy_items.select(index)

func _on_sell_items_item_activated(index):
	party_inventory.add_item(sell_items.get_item_text(index), null, true)
	cost += get_item_cost(sell_items, index) * best_trade_skill/100
	$HBox/ShopFrame/VBox/Amounts/Cost.text = "Cost " + str(cost) + "$"
	sell_items.remove_item(index)
	refresh_pc_sheet_inventories()
	sell_items.select(index)

func _on_party_inventory_item_activated(index):
	sell_items.add_item(party_inventory.get_item_text(index), null, true)
	cost -= get_item_cost(party_inventory, index) * best_trade_skill/100
	$HBox/ShopFrame/VBox/Amounts/Cost.text = "Cost " + str(cost) + "$"
	party_inventory.remove_item(index)
	refresh_pc_sheet_inventories()
	party_inventory.select(index)

func _on_finalize_pressed():
	if (cost == 0 and buy_items.item_count == 0) or cost > int(party_data["money"]):
		return
	
	var i=0
	while i < buy_items.item_count:
		party_inventory.add_item(buy_items.get_item_text(i), null, true)
		i+=1
	buy_items.clear()
	make_inventory_dict()
	party_inventory.clear()
	#move items from sell_items to party_inventory
	i=0
	while i < sell_items.item_count:
		shop_stock.add_item(sell_items.get_item_text(i), null, true)
		i+=1
	sell_items.clear()
	make_shop_dict()
	shop_stock.clear()
	party_data["money"] = party_data["money"] - cost
	$HBox/ShopFrame/VBox/Amounts/Funds.text = "Party has " + str(party_data["money"]) + "$"
	save_stuff()
	exit_trade() #makes trade nodes not visible
	
func _on_haggle_pressed():
	if cost == 0 and buy_items.item_count == 0:
		return
	randomize()
	var rando = randi()%101
	cost -= rando - best_trade_skill
	$HBox/ShopFrame/VBox/Amounts/Cost.text = "Cost " + str(cost) + "$"

func _on_cancel_pressed():
	exit_trade() #makes trade nodes not visible
	
	#move items from buy_items to shop_stock
	var i=0
	while i < buy_items.item_count:
		shop_stock.add_item(buy_items.get_item_text(i), null, true)
		i+=1
	make_shop_dict()
	buy_items.clear()
	shop_stock.clear()
	#move items from sell_items to party_inventory
	i=0
	while i < sell_items.item_count:
		party_inventory.add_item(sell_items.get_item_text(i), null, true)
		print(sell_items.get_item_text(i))
		i+=1
	make_inventory_dict()
	party_inventory.clear()
	sell_items.clear()
	#save shop_stock and party_inventory to file and then clear the itemlist
	save_stuff()
	exit_trade()

func make_inventory_dict():
	Data.inventory.clear()
	var i=0
	while i < party_inventory.item_count:
		Data.inventory[str(i)] = party_inventory.get_item_text(i)
		i+=1

func make_shop_dict():
	stock_dict.clear()
	var i=0
	while i < shop_stock.item_count:
		stock_dict[str(i)] = shop_stock.get_item_text(i)
		i+=1

func save_stuff():
	var save_file = FileAccess.open("user://inventory.save", FileAccess.WRITE)
	var json_string = JSON.stringify(Data.inventory)
	save_file.store_line(json_string)
	save_file.close()
	
	save_file = FileAccess.open("user://leipzig_shop.save", FileAccess.WRITE)
	json_string = JSON.stringify(stock_dict)
	save_file.store_line(json_string)
	save_file.close()

func enter_trade():
	$HBox/Merchant/TextBox.visible = false
	party_inventory.visible = true
	sell_items.visible = true
	buy_items.visible = true
	shop_stock.visible = true
	$HBox/PartyFrame/PartyLabel.visible = true
	$HBox/Merchant/ShopLabel.visible = true
	$HBox/ShopFrame/VBox.visible = true
	cost = 0
	$HBox/ShopFrame/VBox/Amounts/Cost.text = "Cost " + str(cost) + "$"
	$HBox/ShopFrame/VBox/Amounts/Funds.visible = true
	$HBox/ShopFrame/VBox/Amounts/Funds.text = "Party has " + str(party_data["money"]) + "$"
	$HBox/ShopFrame/VBox/Buttons/Cancel.grab_focus()

func exit_trade():
	get_node("HBox/Merchant/TextBox").visible = true
	party_inventory.visible = false
	sell_items.visible = false
	buy_items.visible = false
	shop_stock.visible = false
	$HBox/PartyFrame/PartyLabel.visible = false
	$HBox/Merchant/ShopLabel.visible = false
	$HBox/ShopFrame/VBox.visible = false
	$HBox/ShopFrame/VBox/Amounts/Funds.visible = false
	$HBox/Merchant/TextBox/Options.get_child(0).grab_focus()

func get_keyword(in_string):
	return in_string.get_slice("@", 0)

func get_quality(in_string):
	return in_string.get_slice("@", 1)

func get_item_cost(item_list,index):
	return int(Data.get_node("Items").item_dict[get_keyword(item_list.get_item_text(index))].get_slice("/",1))

func refresh_pc_sheet_inventories():
	Data.inventory.clear()
	for i in party_inventory.item_count:
		Data.inventory[str(i)] = party_inventory.get_item_text(i)

func refresh_shopping_inventories():
	party_inventory.clear()
	for i in party_data["inventory"]:
		party_inventory.add_item(party_data["inventory"][i], null, true)

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
	$FadePanel/Player.play("fade_in_dark")

func fade_in_text():
	$HBox/Merchant/TextBox.visible = true
	$HBox/Merchant/TextBox/Options.get_child(0).grab_focus()
	$HBox/Merchant/TextBox/Player.play("fade_in_text_light")
	$FadePanel/Player.play("fade_out_dark")

