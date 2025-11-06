class_name Camera
extends Camera2D

@export var min_zoom: float = 0.5     # Closest zoom (smaller = closer)
@export var max_zoom: float = 3.0     # Farthest zoom
@export var zoom_speed: float = 0.1   # How much to zoom per scroll
@export var zoom_lerp_speed: float = 8.0  # How quickly to smooth the zoom

var target_zoom: Vector2 = Vector2.ONE

func _ready():
    target_zoom = zoom

func _process(delta):
    # Smoothly interpolate toward target zoom
    zoom = zoom.lerp(target_zoom, zoom_lerp_speed * delta)

func _unhandled_input(event):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            change_zoom(-1)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            change_zoom(1)

func change_zoom(direction: int):
    # Calculate new zoom level
    var new_zoom = target_zoom * (1.0 + direction * zoom_speed)
    # Clamp to limits
    new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
    new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
    target_zoom = new_zoom