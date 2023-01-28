extends Node

var game:Node
var behavior:Node


# self = behavior.advance


func _ready():
	game = get_tree().get_current_scene()
	behavior = get_parent()

 # move_and_attack
func point(unit, objective, smart_move = false):
	behavior.attack.set_target(unit, null)
	if objective: unit.objective = objective
	if (unit.attacks and behavior.move.in_bounds(unit.objective) and
			not unit.retreating and not unit.stunned and not unit.channeling and not unit.command_casting):
		if smart_move:
			var path = behavior.follow.find_path(unit.global_position, unit.objective)
			unit.current_path = path
		var enemies = unit.get_units_in_sight({ "team": unit.opponent_team() })
		var at_objective = (unit.global_position.distance_to(unit.objective) < game.map.half_tile_size)
		var has_path = (unit.current_path.size() > 0)
		if not enemies:
			if not at_objective: move(unit, unit.objective, smart_move) 
			elif has_path: behavior.follow.path(unit, unit.current_path, "advance")
		else:
			var target = behavior.orders.select_target(unit, enemies)
			if not target:
				if not at_objective: move(unit, unit.objective, smart_move)
				elif has_path: behavior.follow.path(unit, unit.current_path, "advance")
			else:
				behavior.attack.set_target(unit, target)
				var target_position = target.global_position + target.collision_position
				if behavior.attack.in_range(unit, target):
					behavior.attack.point(unit, target_position)
				else: move(unit, target_position, smart_move) 


func move(unit, objective, smart_move):
	if unit.moves and objective:
		if smart_move: behavior.move.smart(unit, objective, "advance")
		else : behavior.move.move(unit, objective)
	else: stop(unit)


func on_collision(unit):
	if unit.collide_target == unit.target:
		var target_position = unit.target.global_position + unit.target.collision_position
		behavior.attack.point(unit, target_position)



func resume(unit):
	point(unit, null)


func end(unit):
	if unit.current_destiny != unit.objective:
		point(unit, null)
	else: stop(unit)


func react(target, attacker):
	point(target, attacker.global_position)


func ally_attacked(target, attacker):
	var allies = target.get_units_in_sight({ "team": target.team })
	for ally in allies: react(ally, attacker)


func stop(unit):
	behavior.move.stop(unit)


# uses pathfinder
func smart(unit, objective):
	point(unit, objective, true)
