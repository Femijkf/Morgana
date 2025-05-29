extends Control

@onready var healthBar = $HealthBar
@onready var healthLabel = $Health

var maxHealth: int = 100
var currentHealth: int = 100

func _ready():
	updateHealthBar()
	#await get_tree().create_timer(1.0).timeout
	#takeDamage(30)
	#
	#await get_tree().create_timer(1.0).timeout
	#heal(20)
	#
	#await get_tree().create_timer(1.0).timeout
	#heal(10)
	
func updateHealthBar() -> void:
	healthBar.value = currentHealth
	healthLabel.text = str(currentHealth)
	
func takeDamage(amount: int) -> void:
	currentHealth = max(0, currentHealth - amount)
	updateHealthBar()
	if currentHealth <= 0:
		die()

func heal(amount: int) -> void:
	currentHealth = min(maxHealth, currentHealth + amount)
	updateHealthBar()

func die():
	get_tree().reload_current_scene()
