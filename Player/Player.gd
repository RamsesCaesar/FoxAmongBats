extends KinematicBody2D

const PlayerHurtSound = preload("res://Player/PlayerHurtSound.tscn")
const defeatScreen = preload("res://UI/DefeatScreen.tscn")

export var ACCELERATION = 500
export var MAX_SPEED = 85
export var ROLL_SPEED = 115
export var FRICTION = 500

enum {
	MOVE
	ROLL
	ATTACK
}

var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats

# Links to other Nodes further down the tree:
onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $"HitBoxPivot/Sword-Hitbox"
onready var hurtbox = $HurtBox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	randomize()
	stats.connect("no_health", self, "death")
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector

func death():
	queue_free()
	get_tree().current_scene.get_node("CanvasLayer/DefeatScreen").show()

func _process(delta):
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			roll_state()
		ATTACK:
			attack_state()

# movement:
func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()

	# acceleration:
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		swordHitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		animationState.travel("Run")
	# stopping:
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	if Input.is_action_just_pressed("roll"):
		state = ROLL
	if Input.is_action_just_pressed("attack"):
		state = ATTACK
	move()
# attack:
func attack_state():
	animationState.travel("Attack")
#roll
func roll_state():
	velocity = roll_vector * ROLL_SPEED
	animationState.travel("Roll")
	move()
	
func move():
	velocity = move_and_slide(velocity)

func attack_animation_finished():
	state = MOVE
	
func roll_animation_finished():
	velocity *= 0.8
	state = MOVE


func _on_HurtBox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(1)
	hurtbox.create_hit_effect()
	if stats.health % 2 == 0:
		var playerHurtsound = PlayerHurtSound.instance()
		get_tree().current_scene.add_child(playerHurtsound)


func _on_HurtBox_invincibility_started():
	blinkAnimationPlayer.play("Start")

func _on_HurtBox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
