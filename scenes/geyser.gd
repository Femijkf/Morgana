extends Area2D

# Changed from push_force to a target speed
@export var wind_speed: float = 500.0 
@export var wind_direction: Vector2 = Vector2.UP

var players_in_wind: Array = []
@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Auto-rotate particles to match the wind direction
	if particles:
		particles.rotation = Vector2.UP.angle_to(wind_direction)

func _physics_process(delta: float) -> void:
	# Pass the direction, speed, and delta to Morgana
	for body in players_in_wind:
		if body.has_method("apply_wind"):
			body.apply_wind(wind_direction, wind_speed, delta)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body not in players_in_wind:
		players_in_wind.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body in players_in_wind:
		players_in_wind.erase(body)
