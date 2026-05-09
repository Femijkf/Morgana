extends Area2D

# NEW: Creates a dropdown in the Inspector! (Defaults to Right)
@export_enum("Right:1", "Left:-1") var spawn_facing_direction: int = 1

@onready var collision_shape = $CollisionShape2D
@onready var spawn_point = $SpawnPoint

func _ready():
	pass

func _on_body_entered(body: Node2D):
	if body.has_method("update_camera_limits"):
		var shape = collision_shape.shape as RectangleShape2D
		
		var left = global_position.x - (shape.size.x / 2)
		var right = global_position.x + (shape.size.x / 2)
		var top = global_position.y - (shape.size.y / 2)
		var bottom = global_position.y + (shape.size.y / 2)
		
		body.update_camera_limits(left, right, top, bottom)
		
		# NEW: Update the player's respawn point AND direction!
		if "current_respawn_point" in body:
			body.current_respawn_point = spawn_point.global_position
			body.current_respawn_direction = spawn_facing_direction # Pass the direction
