class_name Bomb
extends Node2D

enum BombState {
    DROPPED,
    CARRIED,
    PLANTED,
    DEFUSING
}

static var DEFUSE_TURN_TIMER := 2

@onready var sprite = $Sprite2D
var curr_bomb_state := BombState.DROPPED
var curr_defuse_timer := DEFUSE_TURN_TIMER

func set_bomb_state(new_state: BombState):
    if new_state == BombState.CARRIED:
        hide()
    elif new_state == BombState.DROPPED:
        show()