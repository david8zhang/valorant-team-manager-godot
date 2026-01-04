class_name Bomb
extends Node2D

enum BombState {
    DROPPED,
    CARRIED,
    PLANTED,
    DEFUSING
}

@onready var sprite = $Sprite2D
var curr_bomb_state := BombState.DROPPED
var bomb_timer := 5

func set_bomb_state(new_state: BombState):
    curr_bomb_state = new_state
    match new_state:
        BombState.CARRIED:
            hide()
        BombState.DROPPED:
            show()
        BombState.PLANTED:
            sprite.self_modulate = Color(1, 0, 0, 0.5)
            show()
        BombState.DEFUSING:
            sprite.self_modulate = Color(0, 0, 1, 0.5)
            show()
