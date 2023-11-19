extends CharacterBody2D

@export var speed = 400
@export var acceleration = 2500
@export var jump_velocity = 580
@export var wall_jump_velocity = 770

@export var tilemap : TileMap

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var _last_wall_dir # int or null

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
	
	# check if we are near a wall
	var near_left = _is_near_wall(-1)
	var near_right = _is_near_wall(1)
	$StateChart.set_expression_property('near_wall', near_left or near_right)
	if near_left:
		_last_wall_dir = -1
	elif near_right:
		_last_wall_dir = 1
	else:
		_last_wall_dir = null
	
	$StateChart.set_expression_property('on_floor', is_on_floor())
	$StateChart.set_expression_property('on_wall', is_on_wall())
	$StateChart.set_expression_property('airborne', not is_on_floor() and not is_on_wall())
	
	if is_on_wall():
		if _last_wall_dir == null: # it is possible to be on_wall without being near_wall in some literal corner cases
			_last_wall_dir = -get_wall_normal().x
		$StateChart.set_expression_property('clinging', sign(direction) == _last_wall_dir)
		
	$StateChart.send_event('tick')
	
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
	InputBuffer.consume_buffered_action('p1_jump')
	$AnimationPlayer.play("jump")
	velocity = Vector2.UP.rotated(PI/3.5 * -_last_wall_dir) * wall_jump_velocity
	
func _on_ascending_state_physics_processing(delta):
	_apply_gravity(delta)
	if velocity.y > 0:
		$StateChart.send_event('end_jump')
	else:
		var head_cell = tilemap.local_to_map(global_position+Vector2(0,-15.9))
		#%TileDebug.position = tilemap.map_to_local(head_cell) # DEBUG
		
		for dir in [-1, 1]:
			var top_tile = head_cell + Vector2i(dir,-1)
			
#			DEBUG
#			if dir == -1:
#				%CollisionTileDebug.position = tilemap.map_to_local(top_tile)
#			else:
#				%CollisionTileDebug2.position = tilemap.map_to_local(top_tile)
				
			var top_tile_data = tilemap.get_cell_tile_data(0, top_tile)
			if top_tile_data and top_tile_data.get_custom_data('corner_dir') == Vector2i(-dir,1): # corner tile facing bottom left or right
				global_position.x = tilemap.map_to_local(top_tile).x - 25 * dir # 16 (tile) + 8 (half tile) + 1 (to avoid collision)
				
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
		
		
func _on_diving_state_entered():
	$AnimationPlayer.play("dive")

func _on_on_floor_state_entered():
	$DebugSprites.show_state('on_floor')

func _on_airborne_state_entered():
	$DebugSprites.show_state('airborne')

func _on_on_wall_state_entered():
	if _last_wall_dir == 1:
		$DebugSprites.show_state('on_wall_right')
	elif _last_wall_dir == -1:
		$DebugSprites.show_state('on_wall_left')
	
func _is_near_wall(dir) -> bool:
	var side_cell = tilemap.local_to_map(global_position+Vector2(dir*15.9,0))
#	%TileDebug.position = tilemap.map_to_local(side_cell) # DEBUG
	
	for y in [-1, 0, 1]:
		var side_tile = side_cell + Vector2i(dir,y)

#		DEBUG
#		if y == 0:
#			%CollisionTileDebug.position = tilemap.map_to_local(side_tile)
#		elif y == 1:
#			%CollisionTileDebug2.position = tilemap.map_to_local(side_tile)
#		else:
#			%CollisionTileDebug3.position = tilemap.map_to_local(side_tile)
			
		if tilemap.get_cell_source_id(0, side_tile) != -1: # not empty
			return true
			
	return false
	

func _on_crouching_state_entered():
	$AnimationPlayer.play("crouch")
	
	%CollisionShape2D.shape.size = Vector2(32, 14)
	%CollisionShape2D.position.y = 9
	
	speed = 150

func _on_crouching_state_exited():
	$AnimationPlayer.play_backwards("crouch")
	
	%CollisionShape2D.shape.size = Vector2(32, 32)
	%CollisionShape2D.position.y = 0
	
	speed = 400 # FIXME need a way to handle modifiers
