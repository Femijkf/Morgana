extends PointLight2D

@onready var animatedSprite2D = $Fire

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animatedSprite2D.play("torch")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
