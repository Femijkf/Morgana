extends Area2D

@onready var collision_shape = $CollisionShape2D

func _ready():
	# Connect the signal through code
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	# Check if the thing that entered has our camera function
	if body.has_method("update_camera_limits"):
		var shape = collision_shape.shape as RectangleShape2D
		
		# Get the exact world coordinates of this room's boundaries
		# global_position is the center. We subtract/add half the size to get the edges.
		var left = global_position.x - (shape.size.x / 2)
		var right = global_position.x + (shape.size.x / 2)
		var top = global_position.y - (shape.size.y / 2)
		var bottom = global_position.y + (shape.size.y / 2)
		
		# Tell the player to snap the camera to this room
		body.update_camera_limits(left, right, top, bottom)
