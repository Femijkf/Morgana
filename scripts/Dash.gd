extends Node2D

# Constants
const DASH_SPEED = 500
const GHOST_SPAWN_INTERVAL = 0.05
const DASH_DURATION = 0.2

# Variables
var is_dashing = false
var dash_direction = 0
var sprite: Sprite2D
var player

# Preloaded Ghost Scene
@onready var ghost_scene = preload("res://scenes/DashGhost.tscn")

# Timer Nodes
@onready var dash_timer: Timer = $DashTimer
@onready var ghost_timer: Timer = $GhostTimer

func start_dash(direction: int, sprite_ref: Sprite2D, player_ref: Node):
	if is_dashing:
		return
	is_dashing = true
	dash_direction = direction
	sprite = sprite_ref
	player = player_ref

	# Start timers
	dash_timer.start(DASH_DURATION)
	ghost_timer.start(GHOST_SPAWN_INTERVAL)

	# Set player's velocity for dash
	player.velocity.x = dash_direction * DASH_SPEED

func _on_DashTimer_timeout():
	is_dashing = false
	player.velocity.x = 0  # Reset velocity
	ghost_timer.stop()

func _on_GhostTimer_timeout():
	spawn_ghost()

func spawn_ghost():
	if sprite:
		var ghost = ghost_scene.instantiate()
		get_parent().add_child(ghost)

		# Set ghost properties based on player
		ghost.global_position = sprite.global_position
		ghost.texture = sprite.texture
		ghost.scale = sprite.scale
		ghost.flip_h = sprite.flip_h
