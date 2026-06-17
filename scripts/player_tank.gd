class_name PlayerTank
extends Tank


func _ready() -> void:
	team = "player"
	body_color = Color("#4ea45f")
	turret_color = Color("#f6d66f")
	speed = 135.0
	fire_cooldown = 0.45
	super()


func _physics_process(delta: float) -> void:
	super(delta)
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if absf(input_direction.x) > absf(input_direction.y):
		input_direction.y = 0.0
	elif input_direction != Vector2.ZERO:
		input_direction.x = 0.0
	drive(input_direction)
	var accept_pressed: bool = InputMap.has_action("ui_accept") and Input.is_action_pressed("ui_accept")
	if Input.is_action_pressed("shoot") or accept_pressed or Input.is_key_pressed(KEY_SPACE):
		shoot()
