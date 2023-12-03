class_name Player extends CharacterBody3D

@onready var camera:Camera3D = $Camera3D
@onready var under_water_filter = $UnderWater/Filter

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed:float = 5
var jump_speed:float = 5
var mouse_sensitivity:float = 0.002
var mouse_captured:bool = false
var max_camera_angle_up:float = deg_to_rad(60)
var max_camera_angle_down:float = -deg_to_rad(40)
var look_up_action:String = "look_up"
var look_down_action:String = "look_down"
var camera_y_axis_inverted:bool = true

func _ready():
	if (GameState.player_state.position != Vector3.ZERO):
		_set_position()
	if (camera_y_axis_inverted):
		look_up_action = "look_down"
		look_down_action = "look_up"
	capture_mouse()

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x, max_camera_angle_down, max_camera_angle_up)

func _physics_process(delta):
	if mouse_captured:
		var joypad_dir: Vector2 = Input.get_vector("look_left", "look_right", look_up_action, look_down_action)
		if joypad_dir.length() > 0:
			var look_dir = joypad_dir * delta
			rotate_y(-look_dir.x)
			camera.rotate_x(-look_dir.y)
			camera.rotation.x = clamp(camera.rotation.x - look_dir.y,  max_camera_angle_down, max_camera_angle_up)
	var is_on_floor = is_on_floor_only() 
	if not is_on_floor:
		velocity.y += -gravity * delta
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var movement_dir = transform.basis * Vector3(input.x, 0, input.y)
	velocity.x = movement_dir.x * speed
	velocity.z = movement_dir.z * speed
	if movement_dir != Vector3.ZERO:
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			if collider == null:
				continue
			if collider.is_in_group("stairs"):
				velocity.y = 1.5
	move_and_slide()
	if is_on_floor and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _on_under_water_body_entered(body):
	under_water_filter.visible = true

func _on_under_water_body_exited(body):
	under_water_filter.visible = false

func _set_position():
	position = GameState.player_state.position
	rotation = GameState.player_state.rotation
	
