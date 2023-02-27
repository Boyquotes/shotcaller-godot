extends ItemList
var game:Node

# self = game.ui.stats

onready var panel = get_node("panel")
onready var hpbar = panel.get_node("hpbar")
onready var unit_name = panel.get_node("name")
onready var hp = panel.get_node("hp")
onready var regen = panel.get_node("regen")
onready var vision = panel.get_node("vision")
onready var control_delay = panel.get_node("control_delay")
onready var damage = panel.get_node("damage")
onready var att_range = panel.get_node("range")
onready var speed = panel.get_node("speed")
onready var gold = panel.get_node("gold")
onready var gold_sprite = panel.get_node("gold_sprite")
onready var portrait_sprite = panel.get_node("portrait/sprite")
onready var level_label : Label = get_node("panel/level_container/level_label")
onready var exp_bar : ProgressBar = get_node("panel/level_container/exp_bar")
onready var status_effect_display = $status_effect_display
onready var active_skills = $active_skills


func _ready():
	game = get_tree().get_current_scene()
	hide()


func update():
	var unit = game.selected_unit
	clear_old_hpbar()
	if not unit: hide()
	else:
		show()
		set_portrait(portrait_sprite, unit)
		add_new_hpbar(unit)
		# stats
		unit_name.text = "%s" % [unit.display_name]
		hp.text = "%s / %s" % [max(unit.current_hp,0), Behavior.modifiers.get_value(unit, "hp")]
		if unit.regen: regen.text = "+%s" % [Behavior.modifiers.get_value(unit, "regen")]
		else: regen.text = ""
		damage.text = "Damage: %s" % Behavior.modifiers.get_value(unit, "damage")
		vision.text = "Vision: %s" % Behavior.modifiers.get_value(unit, "vision")
		att_range.text = "Range: %s" % Behavior.modifiers.get_value(unit, "attack_range")
		if unit.moves: speed.text = "Speed: %s" % Behavior.modifiers.get_value(unit, "speed")
		else: speed.text = ""
		# gold
		if ((game.can_control(unit) and unit.type == "leader")
				or unit.display_name == "mine"):
			gold.text = "%s" % unit.gold
			gold.show()
			gold_sprite.show()
			# xp
			if unit.type == "leader": 
				level_label.show()
				exp_bar.show()
				if unit.curr_control_delay > 0: control_delay.show()
				else: control_delay.hide()
				control_delay.text = "%s" % unit.curr_control_delay
				level_label.text = "Level %d" % unit.level
				exp_bar.value = unit.experience
				exp_bar.max_value = unit.experience_needed()
				# skill
				active_skills.show()
		else:
			gold.hide()
			gold_sprite.hide()
			level_label.hide()
			control_delay.hide()
			exp_bar.hide()
			active_skills.hide()
		status_effect_display.prepare(unit.status_effects)


func set_portrait(portrait, unit):
	var anim = unit.team
	if unit.team == "blue": anim = "default"
	
	var texture_data = unit.body.frames.get_frame(anim, 0)
	portrait.texture = texture_data
	portrait.region_rect.size = texture_data.region.size
	
	var scale = Vector2(2.4,2.4)
	if unit.mounted: scale = Vector2(1.5,1.5)
	if unit.type == "building": scale =  Vector2(1,1)
	match unit.display_name:
		"barrack": scale = Vector2(0.8,0.8)
		"castle": scale = Vector2(0.6,0.6)
	portrait.scale = scale
	var sx = abs(portrait.scale.x)
	portrait.scale.x = -1 * sx if unit.team == "red" else sx


func clear_old_hpbar():
	for old_bar in hpbar.get_children():
		hpbar.remove_child(old_bar)
		old_bar.queue_free()


func add_new_hpbar(unit):
	var red = unit.hud.get_node("hpbar/red").duplicate()
	var green = unit.hud.get_node("hpbar/green").duplicate()
	red.scale *= Vector2(11,11)
	green.scale *= Vector2(11,11)
	hpbar.add_child(red)
	hpbar.add_child(green)


func stats_down(event):
	if event is InputEventMouseButton and not event.pressed: 
		game.selection.unselect()
