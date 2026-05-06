extends CharacterBody2D

const SPEED = 170.0
const JUMP_VELOCITY = -300.0

# Acceleration & Friction
const RUN_ACCEL = SPEED / (6.0/60.0)  # Reaches top speed in ~6 frames
const RUN_DECEL = SPEED / (3.0/60.0) # Stops in ~3 frames

# Wall Jump
const wallBounce = 300
const wallJumpVertical = -300
const wallJumpDuration = 0.3

var wallJumpActive = false
var wallJumpTimer = 0.0 
var wallJumpDirection = 0

# Dash
const dashSpeed = 450
const dashDuration = 0.2

var dashActive = false
var dashAvailable = false
var dashTimer = 0.0
var dashDirection: Vector2 = Vector2.ZERO

var ghostTimer = 0.05  # Time between each ghost
var ghostTimerElapsed = 0.0

# Crouching
const crouchSpeed = 65.0

var crouchActive = false
var underObject = false

# Knockback
var knockback: Vector2 = Vector2.ZERO
var knockbackTimer: float = 0.0
var activeKnockback: Vector2 = Vector2.ZERO
var knockbackActive: bool = false

var isGrabbing = false
var ledge_grab_cooldown: float = 0.0

# Collision Shapes
var standingCollisionShape = preload("res://resources/morgana_collision_shape.tres")
var crouchingCollisionShape = preload("res://resources/morgana_crouch_collision_shape.tres")
var DashGhost = preload("res://scenes/DashGhost.tscn")

#Cutscene
var cutscene_mode: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D 
@onready var collision_shape = $CollisionShape2D
@onready var ceilingRayCast1 = $Ceiling1
@onready var ceilingRayCast2 = $Ceiling2

@onready var grab_hand_right = $GrabHandRayCastRight
@onready var grab_hand_left = $GrabHandRayCastLeft
@onready var grab_check_right =$GrabCheckRayCastRight
@onready var grab_check_left =$GrabCheckRayCastLeft

@onready var healthBar = get_node("/root/level1/CanvasLayer/Control/HealthUI")

@onready var camera: Camera2D = $Camera2D

var current_respawn_point: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# Ledge Hang
	if isGrabbing:
		velocity = Vector2.ZERO
		
		var facing_right = not sprite_2d.flip_h
		if (facing_right and not grab_check_right.is_colliding()) or (not facing_right and not grab_check_left.is_colliding()):
			# The ledge disappeared (it fell)! Force her to drop.
			isGrabbing = false
			sprite_2d.offset.x = 0
			ledge_grab_cooldown = 0.2
			
		# Jump Up
		elif Input.is_action_just_pressed("jump"):
			isGrabbing = false
			sprite_2d.offset.x = 0
			velocity.y = JUMP_VELOCITY
			velocity.x = 50 if facing_right else -50
			ledge_grab_cooldown = 0.3 
			move_and_slide()
			return
		
		# Let Go (Crouch or Down)
		elif Input.is_action_just_pressed("crouch"):
			isGrabbing = false
			sprite_2d.offset.x = 0
			velocity.y = 50 
			ledge_grab_cooldown = 0.4 
			return
			
		else:
			# If we didn't jump, drop, or slip off, stay frozen
			return
	
	# If we are in a cutscene (like a room transition), freeze everything
	if cutscene_mode:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		velocity.y = 0 # FIX: Freeze vertical movement completely
		move_and_slide()
		return # STOP HERE
		
	# Add the gravity (Only if NOT in a cutscene)
	if not is_on_floor() and not dashActive:
		velocity += get_gravity() * delta
	
	# Get the input direction -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")

	# Knockback Logic
	if knockbackTimer > 0.0:
		knockbackActive = true
		activeKnockback = knockback
		knockbackTimer -= delta
		if animation_player.current_animation != "crouch_idle":
			animation_player.play("crouch_idle")
	else:
		knockbackActive = false
		activeKnockback = Vector2.ZERO

	# Handle wall jumping mechanics 9timing)
	if wallJumpActive:
		wallJumpTimer -= delta
		if wallJumpTimer <= 0:
			wallJumpActive = false
	
	# Handle dash mechanics
	if dashActive:
		dashTimer -= delta
		ghostTimerElapsed += delta
		sprite_2d.modulate = Color(255, 255, 255, 0.8)  # White colo
		
		velocity = dashDirection * dashSpeed
		
		# Spawn ghosts during dash
		if ghostTimerElapsed >= ghostTimer:
			spawnDashGhost()
			ghostTimerElapsed = 0.0

		# End dash when the timer runs out
		if dashTimer <= 0:
			dashActive = false
			if velocity.y < 0:
				velocity.y *= 0.4
	else:
		sprite_2d.modulate = Color(1, 1, 1)

	# Overall Movement Control
	if not wallJumpActive and not dashActive:
		var base_speed = crouchSpeed if crouchActive else SPEED
		
		if is_on_floor():
			if direction != 0:
				# Accelerating or turning around
				velocity.x = move_toward(velocity.x, direction * base_speed, RUN_ACCEL * delta)
			else:
				# Letting go of the keys (Decelerating to a stop)
				velocity.x = move_toward(velocity.x, 0, RUN_DECEL * delta)
		else:
			if abs(velocity.x) > base_speed:
				# Increased friction from '2' to '12' to stop the infinite slide
				velocity.x = move_toward(velocity.x, direction * base_speed, SPEED * 12 * delta)
			else:
				# Normal air control
				velocity.x = move_toward(velocity.x, direction * base_speed, SPEED * 5 * delta)
				
		velocity.x += activeKnockback.x


	elif wallJumpActive:
		velocity.x = move_toward(velocity.x, wallJumpDirection * wallBounce, SPEED * delta)
	
	# Flip the Sprite
	if direction > 0 and not wallJumpActive:
		sprite_2d.flip_h = false
	elif direction < 0 and not wallJumpActive:
		sprite_2d.flip_h = true
	
	# Play animations
	if is_on_floor():
		# 1. Highest priority: Dash
		if dashActive:
			animation_player.play("dash")
		# 2. Next priority: Movement (Overrides landing!)
		elif direction != 0 and not crouchActive and not knockbackActive:
			animation_player.play("run")
		# 3. Next priority: Crouching
		elif crouchActive:
			if direction == 0:
				animation_player.play("crouch_idle")
			else:
				animation_player.play("crouch_walk")
		# 4. Lowest priority: Standing still
		elif not knockbackActive:
			# Only play "land" if we just fell and aren't pressing any buttons
			if animation_player.current_animation == "fall":
				animation_player.play("land")
			elif animation_player.current_animation != "land":
				animation_player.play("idle")
				
	elif dashActive:
		animation_player.play("dash")
	else:
		if velocity.y < 0 and animation_player.current_animation != "jump" and not crouchActive:
			animation_player.play("takeoff")
		elif velocity.y > 0 and animation_player.current_animation != "fall":
			if not nextToWall() and not crouchActive:
				animation_player.play("peak")
			elif not crouchActive:
				animation_player.play("wallslide")
			else:
				animation_player.play("crouch_idle")
	
	# Update ledge grab cooldown
	if ledge_grab_cooldown > 0:
		ledge_grab_cooldown -= delta

	# Only check for ledge if cooldown is finished
	if ledge_grab_cooldown <= 0:
		_check_ledge_grab()
	
	# Apply movement
	move_and_slide()
	wallJump()
	dash()
	
	if Input.is_action_just_pressed("crouch"):
		crouch()
	elif Input.is_action_just_released("crouch"):
		if emptyCeiling():
			stand()
		else:
			if not underObject:
				underObject = true
				
	if underObject and emptyCeiling():
		if not Input.is_action_pressed("crouch"):
			stand()
			underObject = false
			

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "takeoff":
		animation_player.play("jump")
	elif anim_name == "peak":
		animation_player.play("fall")

func nextToWall():
	return nextToRightWall() or nextToLeftWall()

func nextToRightWall():
	return $RightWall.is_colliding()

func nextToLeftWall():
	return $LeftWall.is_colliding()

func wallJump():
	if Input.is_action_just_pressed("jump") and Engine.time_scale < 1.0:
		Engine.time_scale = 1.0 # Reset time
		# POWERFUL LAUNCH: 
		# Adjust 600 (horizontal) and -500 (vertical) to fit your cliff gap
		velocity = Vector2(600, -500) 
		
		var manager = get_node_or_null("/root/level1/LevelManager")
		if manager:
			manager.start_falling_sequence()
		return
		
	# Handle jump. 
	# is_action_pressed = hold space jump
	# is_action_just_pressed = press & release space jump
	if Input.is_action_pressed("jump") and (is_on_floor() and emptyCeiling() or isGrabbing):
		isGrabbing = false
		velocity.y = JUMP_VELOCITY
	
	# Handle wall jump
	# WallJump --> velocity off wall, JumpWall --> velcoity of height
	if Input.is_action_just_pressed("jump") and not is_on_floor():
		if nextToRightWall():
			wallJumpActive = true
			wallJumpDirection = -1
			wallJumpTimer = wallJumpDuration
			sprite_2d.flip_h = true
			velocity.x -= wallBounce
			velocity.y = wallJumpVertical
			
		if nextToLeftWall():
			wallJumpActive = true
			wallJumpDirection = 1
			wallJumpTimer = wallJumpDuration
			sprite_2d.flip_h = false
			velocity.x = wallBounce
			velocity.y = wallJumpVertical
			
	if nextToWall() and velocity.y > 30:
		velocity.y = 30
		sprite_2d.flip_h = false
		if nextToRightWall():
			sprite_2d.offset.x = -2
			sprite_2d.flip_h = false
			animation_player.play("wallslide")
		if nextToLeftWall():
			sprite_2d.offset.x = -3
			sprite_2d.flip_h = true
			animation_player.play("wallslide")

func dash():
	# Capture both X and Y inputs 
	var x_dir := Input.get_axis("move_left", "move_right")
	var y_dir := Input.get_axis("jump", "crouch") 
	
	if is_on_floor():
		dashAvailable = true
		
	if Input.is_action_just_pressed("dash") and dashAvailable and not dashActive and not crouchActive:
		dashActive = true
		
		# Combine inputs into a 2D direction
		var input_vector = Vector2(x_dir, y_dir)
		
		# If no buttons are pressed, default to the direction she is facing
		if input_vector == Vector2.ZERO:
			input_vector.x = 1 if not sprite_2d.flip_h else -1
			
		# Normalize the vector to lock the angle and prevent double-speed diagonals
		dashDirection = input_vector.normalized()
		
		# Apply the initial burst of speed in all directions
		velocity = dashDirection * dashSpeed
		
		dashAvailable = false
		dashTimer = dashDuration

func spawnDashGhost():
	# Player Dash Flicker Logic
	var tween = create_tween()
	tween.tween_property($Sprite2D, "material:shader_parameter/amount", 1.0, 0.0)
	tween.tween_property($Sprite2D, "material:shader_parameter/amount", 0.0, 0.3)
	
	var ghost = DashGhost.instantiate()
	var region_rect = Rect2(0, 455, 65, 65)  # Adjust these values for the dash frame
	var ghost_position = global_position + Vector2(-250, -176)
	var ghost_color = Color(255, 255, 255, 0.8)  # Red color with 80% opacity

	ghost.initialize(sprite_2d.texture, ghost_position, region_rect, sprite_2d.flip_h, ghost_color)
	get_parent().add_child(ghost)  # Add the ghost to the scene

func crouch():
	if crouchActive:
		return 
	crouchActive = true
	collision_shape.shape = crouchingCollisionShape
	collision_shape.position.y = -11

func stand():
	if crouchActive == false:
		return
	crouchActive = false
	collision_shape.shape = standingCollisionShape
	collision_shape.position.y = -23

func emptyCeiling() -> bool:
	var result = not ceilingRayCast1.is_colliding() and not ceilingRayCast2.is_colliding()
	return result

func takeDamage(amount: int) -> void:
	# FIX: Only update the health UI if Godot actually found the node!
	if healthBar:
		healthBar.takeDamage(amount)
		
	var tween = create_tween()
	# Take Damage Flicker Logic
	tween.tween_property($Sprite2D, "material:shader_parameter/amount", 0.8, 0.0)
	tween.tween_property($Sprite2D, "material:shader_parameter/amount", 0.0, 0.1).set_delay(0.2)
	
func applyKnockback(direction: Vector2, force: float, knockbackDuration: float) -> void:
	if dashActive: return  # optional dash immunity
	var knockDirection = direction.normalized()
	knockDirection.y = -0.8  # Negative = upward force
	knockback = knockDirection.normalized() * force

	knockbackTimer = knockbackDuration

func _check_ledge_grab():
	if velocity.y < 0 or is_on_floor() or isGrabbing or dashActive or cutscene_mode or ledge_grab_cooldown > 0:
		return

	var right_air = not grab_hand_right.is_colliding()
	var right_wall = grab_check_right.is_colliding()
	var left_air = not grab_hand_left.is_colliding()
	var left_wall = grab_check_left.is_colliding()

	if (right_air and right_wall) or (left_air and left_wall):
		isGrabbing = true
		velocity = Vector2.ZERO
		
		var tile_size = 24
		
		# This math snaps her to the top of whatever tile she is touching
		global_position.y = floor(global_position.y / tile_size) * tile_size + 20
		# NOTE: If she is still too high/low, change '+ 12' to '+ 14' or '+ 10'
		
		if right_wall:
			sprite_2d.flip_h = false
			sprite_2d.offset.x = -5 
		else:
			sprite_2d.flip_h = true
			sprite_2d.offset.x = 0 
			
		animation_player.play("ledge_idle")

func update_camera_limits(left: float, right: float, top: float, bottom: float) -> void:
	# 1. Update the limits
	camera.limit_left = int(left)
	camera.limit_right = int(right)
	camera.limit_top = int(top)
	camera.limit_bottom = int(bottom)
	
	# 2. Trigger the Celeste mid-air freeze
	cutscene_mode = true
	
	# 3. Wait for the camera to pan 
	# (Adjust 0.3 to match your Camera2D's Position Smoothing Speed. 
	# A speed of 7.0 usually takes about 0.3 to 0.4 seconds to settle)
	await get_tree().create_timer(0.3).timeout
	
	# 4. Unfreeze the player
	cutscene_mode = false

func _ready() -> void:
	# Fallback: Default her spawn to wherever you placed her in the editor
	current_respawn_point = global_position


func _on_hazard_dectector_body_entered(_body: Node2D) -> void:
	# Ignore if she's already dead/in a cutscene
	if cutscene_mode:
		return 
		
	die()

func die():
	# 1. Lock player inputs
	cutscene_mode = true 
	
	# 2. Max out the damage
	takeDamage(999) 
	
	# 3. Optional: Add a little "Mario death hop" and freeze horizontal movement
	velocity.x = 0
	velocity.y = -250 
	
	# 4. Wait for 1 second for the death animation/hop to finish
	await get_tree().create_timer(1.0).timeout
	
	# 5. NEW: The Respawn Logic!
	# Teleport Morgana back to the room's spawn point
	global_position = current_respawn_point
	velocity = Vector2.ZERO
	
	# Refill her health via the UI
	if healthBar:
		healthBar.heal(999)
		
	# Snap the camera instantly so it doesn't swoosh across the map
	if camera:
		camera.reset_smoothing()
		
	# Unfreeze her so she can move again
	cutscene_mode = false

func apply_wind(direction: Vector2, speed: float, delta: float) -> void:
	# A massive acceleration value so the wind instantly catches her 
	# and overpowers gravity (which is usually around 980)
	var wind_strength = 3500.0 * delta
	
	# If the wind is blowing left/right, override horizontal speed
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * speed, wind_strength)
		
	# If the wind is blowing up/down, override vertical speed
	if direction.y != 0:
		velocity.y = move_toward(velocity.y, direction.y * speed, wind_strength)
