extends Area2D

const BULLET_SPEED = 40
var shoot_direction = Vector2()
var did_collide = false
func _physics_process(delta: float) -> void:
	position += shoot_direction.normalized() * BULLET_SPEED
	pass

func _on_body_entered(body: Node2D) -> void:
	queue_free()
