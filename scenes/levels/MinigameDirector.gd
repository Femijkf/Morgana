extends Node2D

# Set your specific X coordinates for the 5 lanes in the Inspector!
@export var lanes_x: Array[float] = [100.0, 200.0, 300.0, 400.0, 500.0]
@export var spawn_rate: float = 0.75 # Spawns a hazard every 1 second

@onready var player = get_tree().get_first_node_in_group("player")
@onready var spawn_timer = $SpawnTimer

# Drag your saved LaneHazard.tscn from the FileSystem into this variable!
var hazard_scene = preload("res://scenes/LaneHazard.tscn") 

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# NEW: Listen for Morgana's death! If she dies, run stop_minigame()
	if player:
		player.player_died.connect(stop_minigame)
		
func start_minigame():
	if player:
		# Feed the lane data to Morgana and trigger her falling state
		player.lane_positions = lanes_x
		player.current_lane = 2 # Start in the exact middle lane
		player.lane_fall_mode = true
		player.velocity.y = 0 # Optional: Reset her vertical momentum right as she enters
		
		# --- NEW: TURN OFF CAMERA SMOOTHING ---
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			cam.position_smoothing_enabled = false
		
		# Start spawning hazards
		spawn_timer.start(spawn_rate)

func stop_minigame():
	spawn_timer.stop()
	
	if player:
		player.lane_fall_mode = false
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			cam.position_smoothing_enabled = true
			
	# NEW: Delete every leftover hazard currently in the tunnel
	get_tree().call_group("minigame_hazards", "queue_free")
	
	# NEW: Turn the Start Trigger back on so the player can try again!
	var start_trigger = get_node_or_null("StartTrigger")
	if start_trigger:
		start_trigger.set_deferred("monitoring", true)

func _on_spawn_timer_timeout():
	var hazard = hazard_scene.instantiate()
	
	# Pick a random lane index
	var random_lane = randi() % lanes_x.size()
	
	# Feed the target data to the hazard
	hazard.target_lane_x = lanes_x[random_lane]
	hazard.player_ref = player
	
	add_child(hazard)


func _on_start_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		start_minigame()
		
		# Optional: Turn off the trigger after it's hit so it doesn't fire twice
		$StartTrigger.set_deferred("monitoring", false)


func _on_stop_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		stop_minigame()
		
		# Optional: Turn off the trigger
		$StopTrigger.set_deferred("monitoring", false)
