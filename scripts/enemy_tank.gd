class_name EnemyTank
extends Tank

var _ai_timer := 0.0
var _shoot_timer := 0.0
var _move_direction := Vector2.DOWN
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	team = "enemy"
	body_color = Color("#c94c4c")
	turret_color = Color("#e6b94c")
	speed = 80.0
	fire_cooldown = 1.2
	_rng.randomize()
	super()


func _physics_process(delta: float) -> void:
	super(delta)
	_ai_timer -= delta
	_shoot_timer -= delta
	if _ai_timer <= 0.0:
		_pick_direction()
	if is_on_wall():
		_pick_direction()
	drive(_move_direction)
	if _shoot_timer <= 0.0:
		shoot()
		_shoot_timer = _rng.randf_range(1.0, 2.2)


func _pick_direction() -> void:
	_ai_timer = _rng.randf_range(0.6, 1.7)
	var directions := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	_move_direction = directions[_rng.randi_range(0, directions.size() - 1)]
