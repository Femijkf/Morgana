extends AnimatableBody2D

@export var shake_duration: float = 1.0
@export var fall_speed: float = 400.0
@export var respawn_time: float = 2.0

var is_triggered: bool = false
var is_falling: bool = false

# NEW: A variable to remember where the platform was placed in the editor
var start_position: Vector2 

@onready var sprite: Sprite2D = $Sprite2D
@onready var detector: Area2D = $PlayerDetector
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Save the exact starting coordinate so it knows where to return
	start_position = global_position

func _physics_process(delta: float) -> void:
	# If the fall has started, move the platform straight down
	if is_falling:
		global_position.y += fall_speed * delta

func _on_player_detector_body_entered(body: Node2D) -> void:
	# Check if it's the player, and make sure we haven't already triggered it
	if not is_triggered and body.is_in_group("player"):
		# Check if the player is falling DOWN onto it
		if body.velocity.y >= 0:
			trigger_platform()

func trigger_platform() -> void:
	is_triggered = true
	
	# 1. Shake the Sprite
	var shake_tween = create_tween()
	var start_x = sprite.position.x
	
	for i in range(10):
		var offset = 3 if i % 2 == 0 else -3
		shake_tween.tween_property(sprite, "position:x", start_x + offset, shake_duration / 10.0)
	
	shake_tween.tween_property(sprite, "position:x", start_x, 0.05)
	await shake_tween.finished
	
	# 2. Start the fall
	is_falling = true
	collision_shape.set_deferred("disabled", true)
	
	# 3. Let it fall out of frame for 2 seconds
	await get_tree().create_timer(2.0).timeout
	
	# 4. Stop the falling physics and make it invisible
	is_falling = false
	sprite.hide()
	
	# 5. Wait for the respawn timer
	await get_tree().create_timer(respawn_time).timeout
	
	# 6. Snap it back to the start, turn the sprite back on, and reset everything!
	global_position = start_position
	sprite.show()
	collision_shape.set_deferred("disabled", false)
	is_triggered = false
