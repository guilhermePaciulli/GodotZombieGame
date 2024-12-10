extends CharacterBody2D

const WALK_SPEED = 40
const CLOSE_PLAYER_DISTANCE_MIN = 30

var health = 30
var enemy_did_die = false

# MARK: - Pursuing
var player: Node2D = null
var player_last_seen_location_exists = false
var player_last_seen_location: Vector2
var is_player_in_line_of_sight = false
var is_player_is_in_back_of_line_of_Sight = false
var has_direct_sight_to_player = false
@onready var navigation_agent = $NavigationAgent2D

func _physics_process(delta: float) -> void:
	if enemy_did_die:
		return
	_pursue_player_if_possible()
	_handle_animations()

func _handle_animations():
	if _is_pursuing:
		$animated_sprite.play("walk")
	elif !_is_attacking:
		$animated_sprite.play("idle")

var _is_pursuing = false

func _pursue_player_if_possible():
	var is_player_visible = is_player_in_line_of_sight\
		&& !is_player_is_in_back_of_line_of_Sight\
		&& player_last_seen_location_exists\
		&& has_direct_sight_to_player
	if is_player_visible || !navigation_agent.is_navigation_finished():
		_pursue_player()
	else:
		_is_pursuing = false

func _pursue_player():
	if player_last_seen_location_exists:
		navigation_agent.target_position = player_last_seen_location
	if _is_player_close_to_attack():
		_is_pursuing = false
		_attack()
	else:
		_is_pursuing = true
		var next_position = navigation_agent.get_next_path_position()
		var move_direction = global_position.direction_to(next_position)
		var rounded_direction = Vector2(round(move_direction.x), round(move_direction.y))
		look_at(next_position)
		velocity = rounded_direction * WALK_SPEED
		move_and_slide()

var _is_attacking = false

func _attack():
	if !_is_attacking:
		_is_attacking = true
		$animated_sprite.play("attack_1")
		await get_tree().create_timer(0.4).timeout
		if _is_player_close_to_attack():
			player.hit()
		await get_tree().create_timer(0.5).timeout
		_is_attacking = false

func _is_player_close_to_attack() -> bool:
	return player != null\
		&& global_position.distance_to(player.global_position) < CLOSE_PLAYER_DISTANCE_MIN

func did_hit():
	health -= 10
	_animate_hit()
	if health <= 0 && !enemy_did_die:
		enemy_did_die = true
		$animated_sprite.play("death_1")
		await get_tree().create_timer(1).timeout
		queue_free()

var _is_animating_hit = false
func _animate_hit():
	_is_animating_hit = true
	$animated_sprite.modulate = Color.RED
	await get_tree().create_timer(0.4).timeout
	$animated_sprite.modulate = Color.WHITE

# MARK: - Signals

func _on_line_of_sight_body_entered(body: Node2D) -> void:
	if _is_node_player(body):
		is_player_in_line_of_sight = true
		player = body
		_update_player_last_seen_location(body.global_position)
		
func _on_line_of_sight_body_exited(body: Node2D) -> void:
	if _is_node_player(body):
		is_player_in_line_of_sight = false
		player = null
		_update_player_last_seen_location(body.global_position)

func _on_out_of_sight_body_entered(body: Node2D) -> void:
	if _is_node_player(body):
		is_player_is_in_back_of_line_of_Sight = true
		_update_player_last_seen_location(body.global_position)

func _on_out_of_sight_body_exited(body: Node2D) -> void:
	if _is_node_player(body):
		is_player_is_in_back_of_line_of_Sight = false
		_update_player_last_seen_location(body.global_position)

func _is_node_player(node: Node2D) -> bool:
	return node.is_in_group("player")

func _on_raycast_line_of_sight_timer_timeout() -> void:
	if player != null:
		_point_raycast_to_player()
		if $raycast_line_of_sight.is_colliding():
			var collider = $raycast_line_of_sight.get_collider() as Node2D
			has_direct_sight_to_player = collider != null && collider.is_in_group("player")
			_update_player_last_seen_location(player.global_position)

func _point_raycast_to_player():
	$raycast_line_of_sight.look_at(player.global_position)
	$raycast_line_of_sight.force_raycast_update()

func _update_player_last_seen_location(location: Vector2):
	var is_player_visible = is_player_in_line_of_sight\
		&& !is_player_is_in_back_of_line_of_Sight\
		&& has_direct_sight_to_player
	if is_player_visible:
		player_last_seen_location = location
		player_last_seen_location_exists = true
	else:
		player_last_seen_location_exists = false
