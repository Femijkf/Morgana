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

# Collision Shapes
var standingCollisionShape = preload("res://resources/morgana_collision_shape.tres")
var crouchingCollisionShape = preload("res://resources/morgana_crouch_collision_shape.tres")
var DashGhost = preload("res://scenes/DashGhost.tscn")


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D 
@onready var collision_shape = $CollisionShape2D
@onready var ceilingRayCast1 = $Ceiling1
@onready var ceilingRayCast2 = $Ceiling2

func _physics_process(delta: float) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")

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
		if crouchActive:
			velocity.x = direction * crouchSpeed
		else: 
			velocity.x = direction * SPEED
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
			elif direction == 0 and not crouchActive:
				animation_player.play("idle")
			elif crouchActive:
				if direction == 0:
					animation_player.play("crouch_idle")
				else:
					animation_player.play("crouch_walk")
			else:
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
	# Handle jump. 
	# is_action_pressed = hold space jump
	# is_action_just_pressed = press & release space jump
	if Input.is_action_pressed("jump") and is_on_floor() and emptyCeiling():
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
			sprite_2d.flip_h = false
			animation_player.play("wallslide")
		if nextToLeftWall():
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
	
	var ghost = DashGhost.instantiate()
	var region_rect = Rect2(0, 455, 65, 65)  # Adjust these values for the dash frame
	var ghost_position = global_position + Vector2(2, -25)
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

#func _ready():
	#ensureGhostContainer()
