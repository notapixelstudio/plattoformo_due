extends CharacterBody2D

@export var speed = 400
@export var jump_velocity = 600

const SPEED = 300.0
const JUMP_VELOCITY = 400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	InputBuffer.add_monitored_action('p1_jump')

func _physics_process(delta):
	$StateChart.set_expression_property('velocity', velocity.y)
	
	if is_on_floor():
		$StateChart.send_event('on_floor')
	else:
		$StateChart.send_event('airborne')
	
	if Input.is_action_just_pressed("ui_accept"):
		$StateChart.send_event('start_jump')
		
	if Input.is_action_just_released("ui_accept"):
		$StateChart.send_event('end_jump')
		
	
	var direction = Input.get_axis("p1_left", "p1_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	
	
func _apply_gravity(delta):
	velocity.y += gravity * delta
	
func _apply_strong_gravity(delta):
	velocity.y += 2 * gravity * delta
	
	
func _on_jumping_state_entered():
	$AnimationPlayer.play("jump")
	velocity.y = -jump_velocity

func _on_jumping_state_physics_processing(delta):
	_apply_gravity(delta)
	if velocity.y > 0:
		$StateChart.send_event('end_jump')

func _on_falling_state_physics_processing(delta):
	_apply_strong_gravity(delta)

func _on_coyote_time_state_physics_processing(delta):
	_apply_strong_gravity(delta)

func _on_landing_state_entered():
	var is_jump_action_buffered = InputBuffer.is_action_buffered('p1_jump', 200)
	if is_jump_action_buffered:
		print('Executing buffered jump')
		$StateChart.send_event('start_jump')
	else:
		$AnimationPlayer.play("squash")
