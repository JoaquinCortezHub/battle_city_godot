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
	speed = 300.0
	fire_cooldown = 0.45
	_rng.randomize()
	super()

# Desde acá se maneja el comportamiento de los tanques enemigos, haciendo 3 cosas:
func _physics_process(delta: float) -> void:
	super(delta)
	_ai_timer -= delta
	_shoot_timer -= delta
	if _ai_timer <= 0.0: # 1.Pasado cierto tiempo, cambia de dirección
		_pick_direction()
	if is_on_wall(): # 2. Si se choca con una pared, cambia de dirección
		_pick_direction()
	drive(_move_direction)
	if _shoot_timer <= 0.0: # 3. Si puede disparar, dispara
		shoot()
		_shoot_timer = _rng.randf_range(1.0, 2.2)

# Elige una dirección de forma aleatoria y un tiempo en el que va a mantenerla
func _pick_direction() -> void:
	_ai_timer = _rng.randf_range(0.6, 1.7)
	var directions := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	_move_direction = directions[_rng.randi_range(0, directions.size() - 1)]
