module AZWrapper

import AlphaZero.GI
using StaticArrays
using Yoxii.Game

export YoxiiGameSpec, YoxiiGameEnv

struct YoxiiGameSpec <: GI.AbstractGameSpec end

mutable struct YoxiiGameEnv <: GI.AbstractGameEnv 
    state::State
end

# Game specifications

GI.two_players(::YoxiiGameSpec) = true

GI.actions(::YoxiiGameSpec) = ALL_ACTIONS

const TOTEM::Cell = 8

function GI.vectorize_state(::YoxiiGameSpec, state::State)::Array{Float32}
    board = setcell(state.board, state.totem, TOTEM)
    [
        board[row, column] == value
        for row in 1:BOARD_SIZE,
            column in 1:BOARD_SIZE,
            value in [OUT_OF_BOUNDS, TOTEM, -4, -3, -2, -1, 1, 2, 3, 4]
    ]
end

# Game environements

GI.init(::YoxiiGameSpec)::YoxiiGameEnv = YoxiiGameEnv(init_state())

GI.spec(::YoxiiGameEnv)::YoxiiGameSpec = YoxiiGameSpec()

GI.set_state!(game::YoxiiGameEnv, state::State) = game.state = state

GI.current_state(game::YoxiiGameEnv) = game.state

GI.game_terminated(game::YoxiiGameEnv) = isfinished(game.state)

GI.white_playing(game::YoxiiGameEnv) = game.state.player == WHITE

function GI.actions_mask(game::YoxiiGameEnv)
    all_valid_actions = valid_actions(game.state)
    [action in all_valid_actions for action in ALL_ACTIONS]
end

GI.play!(game::YoxiiGameEnv, action::Action) = game.state = perform_action(game.state, action)

function GI.white_reward(game::YoxiiGameEnv)
    if isfinished(game.state)
        winner = getwinner(game.state)
        winner == WHITE && return 1.
        winner == RED && return -1.
    end
    0.
end

# "optional" functions that test_game() still seems to need

GI.heuristic_value(game::YoxiiGameEnv) = 0.

GI.action_string(::YoxiiGameSpec, action::Action) = "$(action.move) - ($(action.place.row); $(action.place.column)) - $(action.value)"

end