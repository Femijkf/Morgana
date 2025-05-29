extends CharacterBody2D

var speed = 25
var chasePlayer = false
var player = null

func _physics_process(delta: float) -> void:
	if chasePlayer:
		if position.distance_to(player.position) > 35:#Increase this value to account for crouching
			position.x += (player.position.x - position.x) / speed
			$AnimatedSprite2D.play("run")
			if (player.position.x - position.x) < 0:
				$AnimatedSprite2D.flip_h = true
			else:
				$AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("idle")
	move_and_collide(Vector2(0,0))

func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	chasePlayer = true


func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
	chasePlayer = false
