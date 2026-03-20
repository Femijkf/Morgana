##### Spring Modelling

extends Node2D

#the spring's current velocity
var velocity = 0

#the force being applied to the spring
var force = 0

#the current height of the spring
var height = 0

#the natural position of the spring
var target_height = 0

@onready var collision = $Area2D/CollisionShape2D

#the index of this spring
#we will set it on initialize
var index = 0

#how much an external object's movement will affect this spring
var motion_factor = 0.02

#we will trigger this signal to call the splash function
#to make our wave moodel
signal splash

func water_update(spring_constant, dampening):
	## This function applies the hooke's law force to the spring!!
	## This function will be called in each frame
	## hooke's law ---> F = - K * x
	
	#update the height value based on our current position
	height = position.y
	
	#the spring current extension
	var x = height - target_height
	
	var loss = - dampening * velocity
	
	#hooke's law:
	force = -spring_constant * x + loss
	
	#apply the force to the velocity
	#equivalent to the velocity = velocity + force
	velocity += force
	
	#make the spring move!
	position.y += velocity
	pass

func initialize(x_position, id):
	height = position.y
	target_height = position.y
	velocity = 0
	position.x = x_position
	index = id

func set_collision_width(value):
	#this function will set the collision shape size of our springs
	
	# The collision shape size (full width) is set to the distance between springs.
	collision.shape.size = Vector2(value, collision.shape.size.y)
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	#called when a body collides with a spring
	
	# If the body is moving fast, it might have 'tunneled' 
	# We force a splash based on the impact velocity
	process_splash(body)
	
func process_splash(body):
	if "velocity" in body:
		var speed = body.velocity.y * motion_factor
		if speed > 0:
			# If the player is in cutscene mode, ignore the spring's individual trigger
			# because the WaterBodyArea handles it better for high speeds.
			if body.get("cutscene_mode") == true:
				return 
				
			speed = clamp(speed, 0, 10.0)
			emit_signal("splash", index, speed)
	
	#if body is CharacterBody2D:
		## Use the CharacterBody2D's calculated velocity
		#speed = body.velocity.y * motion_factor
	## If the body is a RigidBody2D, 'linear_velocity' should be used, but CharacterBody2D is assumed here.
	#elif "velocity" in body:
		## Fallback check for any node with a velocity property (less safe, but flexible)
		#speed = body.velocity.y * motion_factor 
	#else:
		#return
		#
	## Only splash if the speed is positive (moving downwards into the water)
	#if speed > 0:
		#emit_signal("splash", index, speed)
