class_name Bullet
extends Area2D

signal hit_brick(block: Node)
signal hit_base(team: String)
signal hit_tank(tank: Node)

const SPEED = 430.0

var direction := Vector2.UP
var owner_team := "player"
var travelled := 0.0
var max_distance := 760.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

# Configura la bala cuando aparece siendo disparada
func setup(start_position: Vector2, shoot_direction: Vector2, team: String) -> void:
	global_position = start_position
	direction = shoot_direction.normalized()
	owner_team = team
	rotation = direction.angle() + PI / 2.0

# Va a ir moviendo la bala en cada frame
func _physics_process(delta: float) -> void:
	var step := direction * SPEED * delta
	global_position += step
	travelled += step.length()
	if travelled > max_distance: # Si la bala recorre su distancia máxima, desaparece
		queue_free()

# Acá nos aseguramos de que la bala no aparezca sobre otros objetos
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("brick"):
		hit_brick.emit(body)
		queue_free()
	elif body.is_in_group("steel") or body.is_in_group("arena_wall"):
		queue_free()
	elif body.is_in_group("base"):
		hit_base.emit(owner_team)
		queue_free()
	elif body.is_in_group("tank"):
		if body.team != owner_team:
			hit_tank.emit(body)
			queue_free()

# Maneja el comportamiento entre balas, si dos balas "enemigas" se tocan, desaparecen
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet") and area.owner_team != owner_team:
		area.queue_free()
		queue_free()
