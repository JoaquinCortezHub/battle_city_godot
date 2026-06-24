class_name Tank
extends CharacterBody2D

signal fired(tank: Tank, position: Vector2, direction: Vector2, team: String)
signal destroyed(tank: Tank)

const CELL = 32.0

@export var team := "enemy"
@export var body_color := Color("#c45353")
@export var turret_color := Color("#f0d16a")
@export var speed := 105.0
@export var fire_cooldown := 0.85

var facing := Vector2.UP
var alive := true
var invulnerable := false
var _fire_timer := 0.0
var _invulnerable_timer := 0.0


func _ready() -> void:
	add_to_group("tank")
	_build_visuals()
	_build_collision()

# Baja tiempos de espera e invulnerabilidad en tiempo real
func _physics_process(delta: float) -> void:
	_fire_timer = maxf(0.0, _fire_timer - delta)
	if _invulnerable_timer > 0.0:
		_invulnerable_timer = maxf(0.0, _invulnerable_timer - delta)
		if _invulnerable_timer == 0.0:
			invulnerable = false
			modulate = Color.WHITE

# Toma el input del teclado y mueve el tanque en esa dirección
func drive(input_direction: Vector2) -> void:
	if not alive:
		return
	if input_direction != Vector2.ZERO:
		facing = input_direction.normalized()
		rotation = facing.angle() + PI / 2.0
	velocity = input_direction.normalized() * speed
	move_and_slide()

# Hace que el tanque dispare y pone su disparo en cooldown
func shoot() -> void:
	if not alive or _fire_timer > 0.0:
		return
	_fire_timer = fire_cooldown
	var muzzle := global_position + facing.normalized() * 26.0
	fired.emit(self, muzzle, facing, team)

# Se ejecuta cuando le pegan al tanque
func take_hit() -> void:
	if not alive or invulnerable:
		return
	alive = false
	destroyed.emit(self)
	queue_free()

# Hace al tanque invulnerable
func make_invulnerable(seconds: float) -> void:
	invulnerable = true
	_invulnerable_timer = seconds
	modulate = Color(1.0, 1.0, 1.0, 0.55)

# Asegura que el tanque se choque con los bloques de pared
func _build_collision() -> void:
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 28)
	collision.shape = rect
	add_child(collision)

# Construye las visuales del tanque
func _build_visuals() -> void:
	var body := ColorRect.new()
	body.name = "Body"
	body.color = body_color
	body.size = Vector2(28, 28)
	body.position = Vector2(-14, -14)
	add_child(body)

	var turret := ColorRect.new()
	turret.name = "Turret"
	turret.color = turret_color
	turret.size = Vector2(8, 24)
	turret.position = Vector2(-4, -28)
	add_child(turret)

	var left_track := ColorRect.new()
	left_track.name = "LeftTrack"
	left_track.color = Color("#252934")
	left_track.size = Vector2(6, 30)
	left_track.position = Vector2(-17, -15)
	add_child(left_track)

	var right_track := ColorRect.new()
	right_track.name = "RightTrack"
	right_track.color = Color("#252934")
	right_track.size = Vector2(6, 30)
	right_track.position = Vector2(11, -15)
	add_child(right_track)
