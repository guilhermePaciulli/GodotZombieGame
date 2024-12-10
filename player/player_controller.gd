extends CharacterBody2D

var health = 100

const WALK_SPEED = 50
const RUN_SPEED = 100

@onready var feet_sprite = $feet_sprite
@onready var body_sprite = $body_sprite

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_rotation()
	_handle_feet_animations()
	_handle_body_animations()
	_handle_gunfire()

var isRunning = false

func _handle_movement():
	velocity = Vector2()
	if Input.is_action_pressed("up"):
		velocity.y -= 1
	if Input.is_action_pressed("down"):
		velocity.y += 1
	if Input.is_action_pressed("left"):
		velocity.x -= 1
	if Input.is_action_pressed("right"):
		velocity.x += 1
	velocity = velocity.normalized()
	if Input.is_action_pressed("run"):
		isRunning = true
		velocity = velocity * RUN_SPEED
	else:
		isRunning = false
		velocity = velocity * WALK_SPEED
	move_and_slide()
	
func _handle_rotation():
	look_at(get_global_mouse_position())

func _handle_feet_animations():
	if velocity == Vector2():
		feet_sprite.play("idle")
	elif isRunning:
		feet_sprite.play("run")
	else:
		feet_sprite.play("walk")
	
func _handle_body_animations():
	if velocity == Vector2():
		body_sprite.play("handgun_idle")
	else:
		body_sprite.play("handgun_walk")

const bullet = preload("res://bullet/bullet.tscn")
var gunfire_effect = preload("res://bullet/gunfire_effect.tscn")
var isShooting = false

func _handle_gunfire():
	if Input.is_action_just_released("shoot") && !isShooting:
		isShooting = true
		_fire_bullet()
		_fire_bullet_effect()
		_display_gunfire_effect()
		isShooting = false

func _fire_bullet():
	if $shot_raycast.is_colliding():
		var collider = $shot_raycast.get_collider() as Node2D
		if collider != null && collider.is_in_group("enemy"):
			collider.did_hit()

func _fire_bullet_effect():
	var shoot = bullet.instantiate()
	shoot.position = $gunfire.global_position
	shoot.shoot_direction = $shoot_direction.global_position - $gunfire.global_position
	get_parent().add_child(shoot)

func _display_gunfire_effect():
	var effect = gunfire_effect.instantiate()
	effect.visible = true
	$gunfire.add_child(effect)
	effect.play("shoot")

var _is_animating_hit = false
func hit():
	_animate_hit()
	health -= 10
	if health <= 0:
		queue_free()
	
func _animate_hit():
	_is_animating_hit = true
	$body_sprite.modulate = Color.RED
	$feet_sprite.modulate = Color.RED
	await get_tree().create_timer(0.4).timeout
	$body_sprite.modulate = Color.WHITE
	$feet_sprite.modulate = Color.WHITE
