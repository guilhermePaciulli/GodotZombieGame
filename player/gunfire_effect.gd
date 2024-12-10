extends AnimatedSprite2D

func _process(delta: float) -> void:
	if frame == 63 && visible:
		queue_free()
