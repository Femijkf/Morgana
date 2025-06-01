extends CharacterBody2D

var speed = 25
var chasePlayer = false
var player = null
var damage = 10
var can_attack = true
var inAttackRange = false
var knockbackForce = 150.0
var knockbackDuration = 0.12

@onready var attackCooldownTimer = $AttackCooldown

func _physics_process(delta: float) -> void:
	if chasePlayer and player:
		if position.distance_to(player.position) > 35:
			position.x += (player.position.x - position.x) / speed
			$AnimatedSprite2D.play("run")
			$AnimatedSprite2D.flip_h = (player.position.x - position.x) < 0
		else:
			$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("idle")
	move_and_slide()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		chasePlayer = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		chasePlayer = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		inAttackRange = true
		if not attackCooldownTimer.is_stopped():
			return
		attackCooldownTimer.start()

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		inAttackRange = false
		attackCooldownTimer.stop()

func _on_attack_cooldown_timeout() -> void:
	if inAttackRange and is_instance_valid(player):
		if player.has_method("takeDamage"):
			player.takeDamage(damage)

		if is_instance_valid(player):  # Confirm player still exists before knockback
			var knockbackDirection = (player.global_position - global_position).normalized()
			player.applyKnockback(knockbackDirection, knockbackForce, knockbackDuration)

		attackCooldownTimer.start()
