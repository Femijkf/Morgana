extends CharacterBody2D

@export var lead_distance: float = 250.0  # Pixels the wolf stays ahead
@export var catch_up_speed: float = 5.0   # How "snappy" the wolf follows
@export var gravity: float = 900.0

var active: bool = true #change to false when cutscene before this is active
var player: CharacterBody2D = null

@onready var sprite = $AnimatedSprite2D

func _ready():
	# Find the player automatically when the level starts
	# Ensure your Player node is in a group called "player"
	player = get_tree().get_first_node_in_group("player")
	
	# Start in idle
	sprite.play("idle")

func _physics_process(delta):
	# If we don't have a player yet, keep looking for one
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return # Wait for next frame if player still not found

	if not active:
		# Apply gravity even when not chasing so it doesn't float
		velocity.y += gravity * delta
		move_and_slide()
		return

	# 1. CALCULATE TARGET POSITION
	# We want the wolf to be 'lead_distance' ahead of the player's X
	var target_x = player.global_position.x + lead_distance
	
	# 2. HORIZONTAL MOVEMENT
	# Use 'lerp' for smooth movement. The wolf matches player speed + offset.
	var desired_velocity_x = (target_x - global_position.x) * catch_up_speed
	velocity.x = desired_velocity_x

	# 3. VERTICAL MOVEMENT (Gravity)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# 4. ANIMATION & DIRECTION
	if abs(velocity.x) > 10:
		sprite.play("run")
		sprite.flip_h = velocity.x < 0 # Flip if moving left
	else:
		sprite.play("idle")

	move_and_slide()

# This function will be called by your LevelManager to start the chase
func start_chase():
	active = true
