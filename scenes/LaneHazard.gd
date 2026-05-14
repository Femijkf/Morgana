extends Area2D

@export var rise_speed: float = 400.0 # How fast it shoots up at Morgana
var is_warning: bool = true

var target_lane_x: float = 0.0
var player_ref: Node2D

@onready var warning_label = $WarningLabel
@onready var hazard_sprite = $HazardSprite
@onready var collision = $CollisionShape2D

func _ready():
	# NEW: Adds this hazard to a group via code automatically
	add_to_group("minigame_hazards")
	
	# NEW: Tell the hazard to listen for collisions
	body_entered.connect(_on_body_entered)
	
	# Hide the rock and disable hitboxes initially
	hazard_sprite.hide()
	collision.set_deferred("disabled", true)
	
	# Flash the Warning Label 4 times rapidly
	var tween = create_tween().set_loops(4)
	tween.tween_property(warning_label, "modulate:a", 0.0, 0.12)
	tween.tween_property(warning_label, "modulate:a", 1.0, 0.12)
	
	# Wait 1 full second for the warning phase
	await get_tree().create_timer(1.0).timeout
	
	# Trigger the Hazard!
	is_warning = false
	warning_label.hide()
	hazard_sprite.show()
	collision.set_deferred("disabled", false)
	
	# Clean up memory after it flies past the player
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	if is_warning and player_ref:
		# Keep the warning locked to the bottom of the screen while falling!
		global_position.y = player_ref.global_position.y + 250
		global_position.x = target_lane_x
	elif not is_warning:
		# Blast upwards against the falling player!
		global_position.y -= rise_speed * delta

# NEW: The hazard checks if it hit the player, and if so, runs her die() function!
func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.die()
