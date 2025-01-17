class_name Player extends CharacterBody3D

@onready var camera:Camera3D = $Camera3D
@onready var camera_pivot:Node3D = $Camera3D
@onready var under_water_filter = $UnderWater/Filter
@onready var interactions:Interactions = $Camera3D/RayCastInteractions
@onready var raycast_drop:RayCast3D = $RayCastDrop
@onready var raycast_floor:RayCast3D = $RayCastFloor
@onready var audio:AudioStreamPlayer3D = $AudioStreamPlayer

signal update_oxygen()

var character:Node3D
var anim:AnimationPlayer
var attach_item:Node3D

var sound_walking:AudioStream
var sound_running:AudioStream
@onready var sound_swimming:AudioStream = load("res://assets/audio/water/swimming.mp3")
var current_floor:Floor

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var walking_speed:float = 5
var running_speed:float = 8
var jump_speed:float = 5
var mouse_sensitivity:float = 0.002
var mouse_captured:bool = false
var max_camera_angle_up:float = deg_to_rad(60)
var max_camera_angle_down:float = -deg_to_rad(75)
var look_up_action:String = "look_up"
var look_down_action:String = "look_down"
var mouse_y_axis:int = -1
var previous_position:Vector3

func _ready():
	audio.stream = null
	if (GameState.player_state.position != Vector3.ZERO):
		_set_position()
	set_y_axis()
	set_char()
	capture_mouse()
	update_floor()

func set_char():
	character = Tools.load_char(GameState.player_state.char)
	add_child(character)
	anim = character.get_node("AnimationPlayer")
	attach_item = character.get_node("RootNode/Skeleton3D/HandAttachment/AttachmentPoint")
	anim.play(Consts.ANIM_STANDING)

func set_y_axis():
	if (GameState.settings.mouse_y_axis_inverted):
		mouse_y_axis = 1
	else:
		mouse_y_axis = -1
	if (GameState.settings.joypad_y_axis_inverted):
		look_up_action = "look_down"
		look_down_action = "look_up"
	else:
		look_up_action = "look_up"
		look_down_action = "look_down"

func _unhandled_input(event):
	if event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(event.relative.y * mouse_sensitivity * mouse_y_axis)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, max_camera_angle_down, max_camera_angle_up)

func _process(delta):
	if mouse_captured:
		var joypad_dir: Vector2 = Input.get_vector("look_left", "look_right", look_up_action, look_down_action)
		if joypad_dir.length() > 0:
			var look_dir = joypad_dir * delta
			rotate_y(-look_dir.x * 2.0)
			camera.rotate_x(-look_dir.y)
			camera.rotation.x = clamp(camera.rotation.x - look_dir.y,  max_camera_angle_down, max_camera_angle_up)
	var on_floor = is_on_floor_only() 
	if not on_floor:
		velocity.y += -gravity * delta
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction = transform.basis * Vector3(input.x, 0, input.y)
	var run = Input.is_action_pressed("run")
	var speed = running_speed if run else walking_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if (under_water_filter.visible):
		if (anim.current_animation != Consts.ANIM_SWIMMING):
			anim.play(Consts.ANIM_SWIMMING)
		if (audio.stream != sound_swimming):
			audio.stream = sound_swimming
		if (camera.rotation.x > 0) and (direction != Vector3.ZERO):
			velocity.y += gravity * delta + camera.rotation.x * delta
		update_oxygen.emit()
		if (not audio.playing) :
			audio.play()
		if (audio.stream_paused):
			audio.stream_paused = false
		GameState.oxygen -= 10.0 * delta
		if (GameState.oxygen <= 0):
			audio.stop()
	elif direction != Vector3.ZERO:
		update_floor()
		if run:
			if (anim.current_animation != Consts.ANIM_RUNNING):
				anim.play(Consts.ANIM_RUNNING)
			if (audio.stream != sound_running):
				audio.stream = sound_running
		else:
			anim.play(Consts.ANIM_WALKING)
			if (audio.stream != sound_walking):
				audio.stream = sound_walking
		if (not anim.is_playing()):
			anim.play()
		if (not audio.playing) :
			audio.play()
		if (audio.stream_paused):
			audio.stream_paused = false
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			if collider == null:
				continue
			if collider.is_in_group("stairs"):
				velocity.y = 1.5
	else:
		audio.stream_paused = true
		anim.play(Consts.ANIM_STANDING)
	previous_position = position
	move_and_slide()
	if (previous_position == position):
		audio.stream_paused = true
		anim.play(Consts.ANIM_STANDING)
	if on_floor and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed

func move(pos:Vector3, rot:Vector3):
	position = pos
	rotation = rot

func handle_item():
	attach_item.add_child(GameState.current_item)

func unhandle_item():
	attach_item.remove_child(GameState.current_item)
	
func get_drop_collision():
	raycast_drop.force_raycast_update()
	return raycast_drop.get_collision_point()

func update_floor():
	raycast_floor.force_raycast_update()
	if (raycast_floor.is_colliding()):
		var floor = raycast_floor.get_collider().get_parent()
		if (floor != current_floor) and (floor != null) and (floor is Floor):
			var play = audio.playing
			sound_running = floor.sound_running
			sound_walking = floor.sound_walking
			audio.stream = sound_walking
			current_floor = floor
			if (play):
				audio.play()

func mute():
	audio.stop()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _on_under_water_body_entered(_body):
	under_water_filter.visible = true
	character.rotate_x(deg_to_rad(-90))
	character.position = Vector3(0.0, 0.55, 1.6)

func _on_under_water_body_exited(_body):
	under_water_filter.visible = false
	character.rotate_x(deg_to_rad(90))
	character.position = Vector3.ZERO
	GameState.oxygen = 100.0
	update_oxygen.emit()

func _set_position():
	position = GameState.player_state.position
	rotation = GameState.player_state.rotation

func look_at_node(node:Node3D):
	var pos:Vector3 = node.global_position
	pos.y = position.y
	look_at(pos)

func look_at_char(_char:CharacterBody3D):
	#var pos:Vector3 = _char.global_position
	#pos.y = position.y
	#look_at(pos)
	var pos = global_position
	pos.y = position.y
	_char.look_at(pos)
