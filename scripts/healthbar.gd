extends Control

@onready var healthBar = $HealthBar

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
	
func takeDamage(amount: int) -> void:
	currentHealth = max(0, currentHealth - amount)
	updateHealthBar()
	
	# FIX: Removed the 'die()' call from here so it doesn't conflict 
	# with the player's custom death animation.

func heal(amount: int) -> void:
	currentHealth = min(maxHealth, currentHealth + amount)
	updateHealthBar()
