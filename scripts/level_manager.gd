extends Node

@onready var player = get_tree().get_first_node_in_group("player")
@onready var wolves = get_tree().get_nodes_in_group("chase_wolves")

@onready var jump_hint = $CanvasLayer/JumpHint
@onready var title_card = $CanvasLayer/TitleCard

@export var landing_position_x: float = 3000.0 

func _ready():
	if not player:
		player = get_tree().get_first_node_in_group("player")
	start_opening_cutscene()

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

func start_falling_sequence():
	if jump_hint: jump_hint.hide()
	
	# --- LOCK PLAYER INPUTS ---
	if player:
		player.cutscene_mode = true
		player.velocity.x = 0
		if player.animation_player.has_animation("takeoff"):
			player.animation_player.play("takeoff")
		
		_handle_cinematic_animations()
	
	# --- HARD LOCK CAMERA ---
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		cam.make_current() # Force the camera to be the active one
		# Disable limits temporarily so the camera follows the player into the "void"
		cam.limit_bottom = 1000000 
		
		var cam_tween = create_tween().set_parallel(true)
		# Tight zoom
		cam_tween.tween_property(cam, "zoom", Vector2(1.4, 1.4), 1.0).set_trans(Tween.TRANS_SINE)
		# Push player to middle of left half
		cam_tween.tween_property(cam, "offset:x", 100, 1.0).set_trans(Tween.TRANS_SINE)
	
	# GUIDED X-MOVEMENT
	# We use 'player.global_position.x' to ensure we are moving the actual player
	var move_tween = create_tween()
	move_tween.tween_property(player, "global_position:x", landing_position_x, 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	# --- ARM THE SPLASH ---
	var pool = get_tree().get_first_node_in_group("cinematic_pool")
	if pool:
		pool.cinematic_enabled = true
	
	# --- DELAY BEFORE TITLE FADE ---
	# Wait 3 seconds of falling before the title starts appearing
	await get_tree().create_timer(3.0).timeout
	
	# Fade Title Card
	var title_tween = create_tween()
	title_card.modulate.a = 0 
	title_tween.tween_property(title_card, "modulate:a", 1.0, 1.0)
	
	
	await get_tree().create_timer(3.0).timeout
	
	var fade_out = create_tween()
	fade_out.tween_property(title_card, "modulate:a", 0.0, 1.0)
	
	# --- RESET CAMERA ---
	await fade_out.finished
	if player:
		player.cutscene_mode = false # Returns control to the player
	if cam:
		var cam_reset = create_tween().set_parallel(true)
		cam_reset.tween_property(cam, "offset:x", 0, 1.0)
		cam_reset.tween_property(cam, "zoom", Vector2(1.0, 1.0), 1.0)
		# Reset camera limit to your level's floor if necessary
		cam.limit_bottom = 29875
		
func _handle_cinematic_animations():
	# While she is still going up (takeoff/jump)
	while player.velocity.y < 0:
		await get_tree().process_frame
		# Safety: break if cutscene ends early
		if not player.cutscene_mode: return
		
	# Once velocity.y hits 0 or positive, they have peaked
	if player.animation_player.has_animation("fall"):
		player.animation_player.play("fall")
