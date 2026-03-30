extends Node

# --- REFERENCES ---
@onready var player = get_tree().get_first_node_in_group("player")
@onready var wolves = get_tree().get_nodes_in_group("chase_wolves")

@onready var jump_hint = $CanvasLayer/JumpHint
@onready var title_card = $CanvasLayer/TitleCard

# --- CONFIGURATION ---
@export var landing_position_x: float = 3000.0 

func _ready():
	if not player:
		player = get_tree().get_first_node_in_group("player")
	start_opening_cutscene()

# --- CAMERA SHAKE SYSTEM ---
func shake_camera(intensity: float, duration: float):
	var cam = player.get_node_or_null("Camera2D")
	if cam:
		var shake_tween = create_tween()
		var current_x_offset = cam.offset.x 
		
		# Increased iterations (12) and used shorter intervals for a "sharper" shake
		for i in range(12):
			var target_offset = Vector2(
				current_x_offset + randf_range(-intensity, intensity), 
				randf_range(-intensity, intensity)
			)
			shake_tween.tween_property(cam, "offset", target_offset, duration / 12.0)
		
		# Snap back to the cinematic offset before the final sequence ends
		shake_tween.tween_property(cam, "offset", Vector2(current_x_offset, 0), 0.05)

# --- STEP 1: OPENING CUTSCENE ---
func start_opening_cutscene():
	if player:
		player.set_physics_process(false)
	await get_tree().create_timer(1.5).timeout
	for wolf in wolves:
		wolf.active = true
		wolf.lead_distance = 600 
	await get_tree().create_timer(1.0).timeout
	if player:
		player.set_physics_process(true)
	if wolves.size() > 0:
		var tween = create_tween()
		for wolf in wolves:
			tween.tween_property(wolf, "lead_distance", 250.0, 2.0)

# --- STEP 2: CLIFF JUMP TRIGGER ---
func trigger_cliff_jump():
	Engine.time_scale = 0.4 
	if jump_hint:
		jump_hint.show()

func _on_jump_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		trigger_cliff_jump()
		if body is CharacterBody2D:
			var trigger_node = get_node_or_null("../JumpTrigger")
			if trigger_node:
				trigger_node.set_deferred("monitoring", false)

# --- STEP 3: CINEMATIC FALLING SEQUENCE ---
func start_falling_sequence():
	if jump_hint: jump_hint.hide()
	
	# Lock Inputs & Clear Horizontal Momentum
	if player:
		player.cutscene_mode = true
		player.velocity.x = 0
		if player.animation_player.has_animation("takeoff"):
			player.animation_player.play("takeoff")
		_handle_cinematic_animations()
	
	# Camera Setup (Zoom & Shift)
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		cam.make_current()
		cam.limit_bottom = 1000000 
		var cam_tween = create_tween().set_parallel(true)
		cam_tween.tween_property(cam, "zoom", Vector2(2.4, 2.4), 1.0).set_trans(Tween.TRANS_SINE)
		cam_tween.tween_property(cam, "offset:x", 60, 1.0).set_trans(Tween.TRANS_SINE)
		cam_tween.tween_property(cam, "offset:y", -20, 1.0).set_trans(Tween.TRANS_SINE)
	
	# Guided Movement
	var move_tween = create_tween()
	move_tween.tween_property(player, "global_position:x", landing_position_x, 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	# Arm the Water Splash
	var pool = get_tree().get_first_node_in_group("cinematic_pool")
	if pool:
		pool.cinematic_enabled = true
	
	# Delay for Cinematic Tension
	await get_tree().create_timer(3.0).timeout
	
	# Fade In Title Card
	var title_tween = create_tween()
	title_card.modulate.a = 0 
	title_tween.tween_property(title_card, "modulate:a", 1.0, 1.0)
	
	await get_tree().create_timer(3.0).timeout
	
	# Fade Out Title Card
	var fade_out = create_tween()
	fade_out.tween_property(title_card, "modulate:a", 0.0, 1.0)
	
	# --- STEP 4: RECOVERY & CAMERA CENTERING ---
	await fade_out.finished
	if player:
		player.cutscene_mode = false 
		
	if cam:
		var cam_reset = create_tween().set_parallel(true)
		# Forces both X and Y offsets back to 0
		cam_reset.tween_property(cam, "offset", Vector2.ZERO, 1.0).set_trans(Tween.TRANS_SINE)
		cam_reset.tween_property(cam, "zoom", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)
		cam.limit_bottom = 29875
		
# --- HELPER: ANIMATION HANDLING ---
func _handle_cinematic_animations():
	while player.velocity.y < 0:
		await get_tree().process_frame
		if not player.cutscene_mode: return
		
	if player.animation_player.has_animation("fall"):
		player.animation_player.play("fall")
