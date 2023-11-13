extends CharacterBody2D

@export var speed = 400
@export var acceleration = 2500
@export var jump_velocity = 600
@export var wall_jump_velocity = 800

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var last_valid_wall_normal : Vector2

func _ready():
	InputBuffer.add_monitored_action('p1_jump')
	
func _get_direction():
	return Input.get_axis("p1_left", "p1_right")

func _physics_process(delta):
	var direction = _get_direction()
	velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	
	$StateChart.set_expression_property('velocity', velocity)
	$StateChart.set_expression_property('clinging', false)
	$StateChart.set_expression_property('heading_down', Input.get_action_strength("p1_down") > 0)
	
	if is_on_floor():
		$StateChart.send_event('on_floor')
	elif is_on_wall():
		$StateChart.set_expression_property('clinging', sign(direction) == -get_wall_normal().x)
		$StateChart.send_event('on_wall')
		last_valid_wall_normal = get_wall_normal()
	else:
		$StateChart.send_event('airborne')
	
	if Input.is_action_just_pressed("p1_jump"):
		$StateChart.send_event('start_jump')
		
	if Input.is_action_just_released("p1_jump"):
		$StateChart.send_event('end_jump')
		
	move_and_slide()
	
	
func _apply_gravity(delta):
	velocity.y += gravity * delta
	
func _apply_strong_gravity(delta):
	velocity.y += 2 * gravity * delta
	
func _apply_super_strong_gravity(delta):
	velocity.y += 3 * gravity * delta
	
func _apply_weak_gravity(delta):
	velocity.y += 0.3 * gravity * delta
	
	
func _on_jumping_state_entered():
	InputBuffer.consume_buffered_action('p1_jump')
	$AnimationPlayer.play("jump")
	velocity.y = -jump_velocity
	
func _on_wall_jumping_state_entered():
	$AnimationPlayer.play("jump")
	velocity = Vector2.UP.rotated(PI/3.5 * last_valid_wall_normal.x) * wall_jump_velocity
	
func _on_ascending_state_physics_processing(delta):
	_apply_gravity(delta)
	if velocity.y > 0:
		$StateChart.send_event('end_jump')

func _on_falling_state_physics_processing(delta):
	_apply_strong_gravity(delta)
	
func _on_diving_state_physics_processing(delta):
	_apply_super_strong_gravity(delta)

func _on_coyote_time_state_physics_processing(delta):
	_apply_strong_gravity(delta)
	
func _on_coyote_time_wall_state_physics_processing(delta):
	_apply_strong_gravity(delta)
	
func _on_sliding_down_state_entered():
	velocity.y = 0
	
func _on_sliding_down_state_physics_processing(delta):
	_apply_weak_gravity(delta)
	
func _on_sliding_up_state_physics_processing(delta):
	_apply_strong_gravity(delta)

func _on_landing_state_entered():
	if InputBuffer.is_action_buffered('p1_jump', 200):
		print('Executing buffered jump')
		$StateChart.send_event('start_jump')
	else:
		$AnimationPlayer.play("squash")
		
func _on_on_wall_state_entered():
	if InputBuffer.is_action_buffered('p1_jump', 200):
		print('Executing buffered wall jump')
		$StateChart.send_event('start_jump')
		
