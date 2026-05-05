extends Sprite2D

@export var fade_speed = 2.0  # How quickly the ghost fades out (higher is faster)
@onready var timer: Timer = $Timer

# Initialize the ghost with the required parameters
func initialize(_texture: Texture2D, _position: Vector2, _region_rect: Rect2, _flip_h: bool, _color: Color):
	self.texture = _texture
	self.position = _position
	self.region_enabled = true
	self.region_rect = _region_rect
	self.flip_h = _flip_h
	modulate = _color  # Apply the color to the ghost
	self.z_index = -1

func _ready():
	timer.start()  # Start the timer when the ghost is created
	timer.timeout.connect(_on_timer_timeout)

func _process(delta):
	# Gradually fade out the ghost
	if modulate.a > 0:  # Only fade while visible
		modulate.a = max(0, modulate.a - fade_speed * delta)

func _on_timer_timeout():
	queue_free()  # Remove the ghost after the timer finishes
