extends Control
var game:Node

# self = game.ui.inventories

var cleared = false
var gold = 0

const equip_items_max = 2
const consumable_items_max = 1

const delivery_time = 2

# Dictionary of all leaders inventories
var leaders = {}
var deliveries = {}


var item_button_preload = preload("res://items/button/item_button.tscn")
var sell_button_margin = 40


func _ready():
	game = get_tree().get_current_scene()
	
	hide()
	clear()


func clear():
	if not cleared:
		var placeholder = self.get_node("placeholder")
		self.remove_child(placeholder)
		placeholder.queue_free()
		cleared = true


func new_inventory(leader):
	
	var extra_gold = 0
	if leader.display_name in game.unit.skills.leader:
		var leader_skills = game.unit.skills.leader[leader.display_name]
		if "extra_gold" in leader_skills:
				extra_gold = leader_skills.extra_gold
	
	var inventory = {
		"container": HBoxContainer.new(),
		"gold": 0,
		"extra_gold": extra_gold,
		"leader": null,
		"equip_items": [],
		"consumable_items":[],
		"equip_item_buttons": [],
		"consumable_item_buttons": []
	}
	
	inventory.container.margin_top = sell_button_margin
# warning-ignore:unused_variable
	for index in range(equip_items_max):
		inventory.equip_items.append(null)
# warning-ignore:unused_variable
	for index in range(consumable_items_max):
		inventory.consumable_items.append(null)
	return inventory


func build_leaders():
	for leader in game.player_leaders:
		add_inventory(leader)
	gold_update_cycle()


func gold_update_cycle():
	game.ui.shop.update_buttons()
	update_buttons()
	yield(get_tree().create_timer(1), "timeout")
	gold_update_cycle()


func add_inventory(leader):
	# Setup GUI for inventory
	var inventory = new_inventory(leader)
	add_child(inventory.container)
	leaders[leader.name] = inventory
	inventory.leader = leader
	gold_timer_timeout(inventory)
	var counter = 0
	var item_button
# warning-ignore:unused_variable
	for i in range(equip_items_max):
		item_button = item_button_preload.instance()
		inventory.equip_item_buttons.append(item_button)
		inventory.container.add_child(item_button)
		item_button.index = counter
		counter += 1
		item_button.setup(null)
# warning-ignore:unused_variable
	for i in range(consumable_items_max):
		item_button = item_button_preload.instance()
		inventory.consumable_item_buttons.append(item_button)
		inventory.container.add_child(item_button)
		item_button.index = counter
		counter += 1
		item_button.setup(null)
		

func gold_timer_timeout(inventory):
	inventory.gold += 1 + inventory.extra_gold
	# Updates gold label
	if game.selected_leader: game.ui.stats.update()
	yield(get_tree().create_timer(1), "timeout")
	gold_timer_timeout(inventory)



func equip_items_has_slots(leader_name):
	var inventory = leaders[leader_name]
	for item in inventory.equip_items:
		if item == null:
			return true
	return false



func consumable_items_has_slots(leader_name):
	var inventory = leaders[leader_name]
	for item in inventory.consumable_items:
		if item == null:
			return true
	return false



func add_delivery(leader, item):
	var new_delivery = {
		"item": item,
		"leader": leader,
		"time": item.delivery_time+1,
		"index": 0,
		"label": null,
		"button": null
	}
	deliveries[leader.name] = new_delivery
	
	var inventory = leaders[leader.name]
	
	if item.type == "equip":
		for index in range(equip_items_max):
			if inventory.equip_items[index] == null:
				new_delivery.index = index
				new_delivery.button = inventory.equip_item_buttons[index]
				new_delivery.label = new_delivery.button.price_label
				break
	elif item.type == "consumable":
		for index in range(consumable_items_max):
			if inventory.consumable_items[index] == null:
				new_delivery.index = index
				new_delivery.button = inventory.consumable_item_buttons[index]
				new_delivery.label = new_delivery.button.price_label
				break
	
	delivery_timer(new_delivery)


func delivery_timer(delivery):
	delivery.label.show()
	delivery.time -= 1
	if delivery.time > 0:
		delivery.label.text = "0:0"+str(delivery.time)
		yield(get_tree().create_timer(1), "timeout")
		delivery_timer(delivery)
	else:
		match delivery.item.type:
			"consumable": give_item(delivery)
			"equip":
				if game.ui.shop.close_to_blacksmith(delivery.leader): 
					give_item(delivery)
				else: 
					var inventory = leaders[delivery.leader.name]
					var index = delivery.index
					inventory.equip_items[index] = delivery.item
					delivery.item.ready = true
					delivery.label.text = "ready"


func is_delivering(leader):
	if leader.name in game.ui.inventories.deliveries:
		var delivery = game.ui.inventories.deliveries[leader.name]
		return (delivery.time > 0)
	else: return false


func give_item(delivery):
	var leader = delivery.leader
	var inventory = leaders[leader.name]
	var item = delivery.item
	var index = delivery.index
	
	deliveries.erase(leader.name)
	
	match item.type:
		"equip":
			inventory.equip_items[index] = item
			inventory.equip_item_buttons[index].setup(item)
			for key in item.attributes.keys():
				match key:
					"hp":
						leader.current_hp += item.attributes[key]
					"damage":
						leader.current_damage += item.attributes[key]
					
				leader[key] += item.attributes[key]
		"consumable":
			inventory.consumable_items[index] = item
			inventory.consumable_item_buttons[index].setup(item)
	
	item.delivered = true
	
	game.unit.hud.update_hpbar(leader)



func remove_item(leader, index):
	var leader_items = leaders[leader.name].equip_items + leaders[leader.name].consumable_items
	var item = leader_items[index]
	
	if item.type == "equip":
		# Remove attributes that were added when purchasing an item
		for key in item.attributes.keys():
			match key:
				"hp":
					leader.current_hp -= item.attributes[key]
				"damage":
					leader.current_damage -= item.attributes[key]
			leader[key] -= item.attributes[key]
			
		leaders[leader.name].equip_items[index] = null
	elif item.type == "consumable":
		leaders[leader.name].consumable_items[index - equip_items_max] = null
	
	leader.get_node("hud").update_hpbar(leader)
	
	
	return item



func setup_items(leader_name):
	var counter = 0
	var inventory = leaders[leader_name]
	for item in inventory.equip_items:
		inventory.equip_item_buttons[counter].setup(item)
		counter += 1
	counter = 0
	for item in inventory.consumable_items:
		inventory.consumable_item_buttons[counter].setup(item)
		counter += 1
		
	update_buttons()
	game.ui.stats.update()



	# Disable potion if full heath
func update_consumables(leader):
	var inventory = leaders[leader.name]
	var counter = 0
	for item in inventory.consumable_items:
		var item_button = inventory.consumable_item_buttons[counter]
		item_button.disabled = (leader.current_hp >= leader.hp)
		counter += 1



func update_buttons():
	for leader in game.player_leaders:
		var inventory = leaders[leader.name]
		var close_to_blacksmith = game.ui.shop.close_to_blacksmith(leader)
		inventory.container.hide()
		# deliver ready items
		if close_to_blacksmith:
			for item in inventory.equip_items:
				if item and item.ready and not item.delivered:
					var ready_delivery = deliveries[leader.name]
					give_item(ready_delivery)
	
	if game.selected_leader and game.selected_leader.name in leaders:
		var leader = game.selected_leader
		var inventory = leaders[leader.name]
		var close_to_blacksmith = game.ui.shop.close_to_blacksmith(leader)
		
		show()
		inventory.container.show()
		update_consumables(leader)
		
		
		# toggle sell buttons
		if game.ui.shop.visible and close_to_blacksmith:
			var counter = 0
			for item in inventory.equip_items:
				inventory.equip_item_buttons[counter].show_sell_button()
				counter += 1
			counter = 0
			for item in inventory.consumable_items:
				inventory.consumable_item_buttons[counter].show_sell_button()
				counter += 1
		else:
			for item_button in inventory.equip_item_buttons + inventory.consumable_item_buttons:
				item_button.sell_button.hide()
		
