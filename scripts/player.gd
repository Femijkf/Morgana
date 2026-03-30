extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# Wall Jump
const wallBounce = 300
const wallJumpVertical = -300
const wallJumpDuration = 0.3

var wallJumpActive = false
var wallJumpTimer = 0.0 
var wallJumpDirection = 0

# Dash
const dashSpeed = 500
const dashDuration = 0.2

var dashActive = false
var dashAvailable = false
var dashTimer = 0.0
var dashDirection = 0

var ghostTimer = 0.05  # Time between each ghost
var ghostTimerElapsed = 0.0

# Crouching
const crouchSpeed = 65

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

@onready var healthBar = get_node("/root/Game/CanvasLayer/Control/HealthUI")

func _physics_process(delta: float) -> void:
	# Ledge Hang
	if isGrabbing:
		velocity = Vector2.ZERO
		
		# Jump Up
		if Input.is_action_just_pressed("jump"):
			isGrabbing = false
			sprite_2d.offset.x = 0
			velocity.y = JUMP_VELOCITY
			velocity.x = 50 if not sprite_2d.flip_h else -50
			ledge_grab_cooldown = 0.3 # Brief cooldown after jumping up
			move_and_slide()
		
		# Let Go (Crouch or Down)
		elif Input.is_action_just_pressed("crouch") or Input.is_action_pressed("ui_down"):
			isGrabbing = false
			sprite_2d.offset.x = 0
			velocity.y = 50 # Give a little downward push
			ledge_grab_cooldown = 0.4 # Longer cooldown so she falls past the ledge
			
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# If we are in a cutscene, don't allow player movement inputs
	if cutscene_mode:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta) # Slow down X naturally
		move_and_slide()
		return # STOP HERE
	
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

		# Spawn ghosts during dash
		if ghostTimerElapsed >= ghostTimer:
			spawnDashGhost()
			ghostTimerElapsed = 0.0

		# End dash when the timer runs out
		if dashTimer <= 0:
			dashActive = false
			velocity.x = 0  # Stop the dash movement
	else:
		sprite_2d.modulate = Color(1, 1, 1)

	# Overall Movement Control
	if not wallJumpActive and not dashActive:
		var base_speed = crouchSpeed if crouchActive else SPEED
		velocity.x = direction * base_speed + activeKnockback.x
		if knockbackActive:
			velocity.y = activeKnockback.y


	elif wallJumpActive:
		velocity.x = move_toward(velocity.x, wallJumpDirection * wallBounce, SPEED * delta)
	
	# Flip the Sprite
	if direction > 0 and not wallJumpActive:
		sprite_2d.flip_h = false
	elif direction < 0 and not wallJumpActive:
		sprite_2d.flip_h = true
	
	# Play animations
	if is_on_floor():
		if animation_player.current_animation == "fall":
			animation_player.play("land")
		elif animation_player.current_animation != "land":
			if (direction == 0 and dashActive) or (direction != 0 and dashActive):
				animation_player.play("dash")
			elif direction == 0 and not crouchActive and not knockbackActive:
				animation_player.play("idle")
			elif crouchActive:
				if direction == 0:
					animation_player.play("crouch_idle")
				else:
					animation_player.play("crouch_walk")
			elif not knockbackActive:
				animation_player.play("run")
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
			sprite_2d.offset.x = 0
			sprite_2d.flip_h = false
			animation_player.play("wallslide")
		if nextToLeftWall():
			sprite_2d.offset.x = -1
			sprite_2d.flip_h = true
			animation_player.play("wallslide")

func dash():
	var direction := Input.get_axis("move_left", "move_right")
	if is_on_floor():
		dashAvailable = true
		
	if Input.is_action_just_pressed("dash") and dashAvailable and not dashActive and not crouchActive:
		dashActive = true
		dashDirection = direction if direction != 0 else (1 if sprite_2d.flip_h == false else -1)
		velocity.x = dashDirection * dashSpeed
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
			sprite_2d.offset.x = -3 
		else:
			sprite_2d.flip_h = true
			sprite_2d.offset.x = 2 
			
		animation_player.play("ledge_idle")

#func _ready():
	#ensureGhostContainer()
