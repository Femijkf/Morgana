extends Sprite2D

@export var fade_speed = 2.0  # How quickly the ghost fades out (higher is faster)
@onready var timer: Timer = $Timer

# Initialize the ghost with the required parameters
func initialize(texture: Texture2D, position: Vector2, region_rect: Rect2, flip_h: bool, color: Color):
	self.texture = texture
	self.position = position
	self.region_enabled = true
	self.region_rect = region_rect
	self.flip_h = flip_h
	modulate = color  # Apply the color to the ghost
	self.z_index = 0

func _ready():
	timer.start()  # Start the timer when the ghost is created
	timer.timeout.connect(_on_timer_timeout)

func _process(delta):
	# Gradually fade out the ghost
	if modulate.a > 0:  # Only fade while visible
		modulate.a = max(0, modulate.a - fade_speed * delta)

func _on_timer_timeout():
	queue_free()  # Remove the ghost after the timer finishes
