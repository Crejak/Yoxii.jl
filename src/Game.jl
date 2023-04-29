module Game

using StaticArrays

#################
# Game parameters
#################

export BOARD_SIZE

const BOARD_SIZE = 7

##################
# Type definitions
##################

export Player, PieceValue, Hand, Cell, Board, Position, Direction, Action, State
export NORTH, NORTH_EAST, EAST, SOUTH_EAST, SOUTH, SOUTH_WEST, WEST, NORTH_WEST

const Player = Bool

const PieceValue = UInt8
const Hand = SVector{4, UInt8}
const Cell = Int8

const Board = SMatrix{BOARD_SIZE, BOARD_SIZE, Cell}

struct Position
    row::Int
    column::Int
    Position(row, column) = new(row, column)
    Position((row, column)) = new(row, column)
end

@enum Direction NORTH NORTH_EAST EAST SOUTH_EAST SOUTH SOUTH_WEST WEST NORTH_WEST

struct Action
    move::Direction
    place::Position
    value::PieceValue
end

struct State
    board::Board
    totem::Position
    player::Player
    white_hand::Hand
    red_hand::Hand
end

########
# Consts
########

export WHITE, RED, INITIAL_HAND, EMPTY, OUT_OF_BOUNDS, ALL_ACTIONS

const WHITE::Player = true
const RED::Player = false

const INITIAL_HAND::Hand = @SVector [5, 5, 5, 3]

const EMPTY::Cell = 0
const OUT_OF_BOUNDS::Cell = 9

const ALL_ACTIONS = vec([Action(d, Position(r, c), v) for d in instances(Direction), r in 1:BOARD_SIZE, c in 1:BOARD_SIZE, v in 1:4])

################
# Init functions
################

export init_board, init_state

"Create an initial, emtpy board"
function init_board()::Board
    builder = [EMPTY for _ in 1:BOARD_SIZE, _ in 1:BOARD_SIZE]
    builder[1, 1] = OUT_OF_BOUNDS
    builder[1, 2] = OUT_OF_BOUNDS
    builder[2, 1] = OUT_OF_BOUNDS
    builder[end, 1] = OUT_OF_BOUNDS
    builder[end, 2] = OUT_OF_BOUNDS
    builder[end-1, 1] = OUT_OF_BOUNDS
    builder[end, end] = OUT_OF_BOUNDS
    builder[end, end-1] = OUT_OF_BOUNDS
    builder[end-1, end] = OUT_OF_BOUNDS
    builder[1, end] = OUT_OF_BOUNDS
    builder[1, end-1] = OUT_OF_BOUNDS
    builder[2, end] = OUT_OF_BOUNDS
    Board(builder)
end

init_state() = State(init_board(), Position(4, 4), WHITE, copy(INITIAL_HAND), copy(INITIAL_HAND))

################
# Hand functions
################

export decrement

function decrement(hand::Hand, value::PieceValue)::Hand
    mutable_hand = MVector(hand)
    mutable_hand[value] -= 1
    Hand(mutable_hand)
end

################
# Cell functions
################

export isplayer

Cell(value::PieceValue, player::Player) = player == WHITE ? Cell(value) : Cell(-Int(value))

isplayer(cell::Cell) = 1 <= abs(cell) <= 4
isplayer(cell::Cell, player::Player) = isplayer(cell) && (player == WHITE && cell > 0 || player == RED && cell < 0)

####################
# Position functions
####################

export delta, +

direction_delta_map = Dict(
    NORTH => (-1, 0),
    NORTH_EAST => (-1, 1),
    EAST => (0, 1),
    SOUTH_EAST => (1, 1),
    SOUTH => (1, 0),
    SOUTH_WEST => (1, -1),
    WEST => (0, -1),
    NORTH_WEST => (-1, -1)
)
delta(direction::Direction)::Position = Position(direction_delta_map[direction])

Base.copy(position::Position) = Position(position.row, position.column)
Base.:+(a::Position, b::Position) = Position(a.row + b.row, a.column + b.column)

#################
# Board functions
#################

# Exceptions

export OutOfBoundsException

struct OutOfBoundsException <: Exception end

# Functions

export getcell, setcell, empty_positions_except, empty_positions_around
export getscore, player_pieces_around

function getcell(board::Board, position::Position)::Cell
    if 1 <= position.row <= BOARD_SIZE && 1 <= position.column <= BOARD_SIZE
        board[position.row, position.column] 
    else
        OUT_OF_BOUNDS
    end
end

function setcell(board::Board, position::Position, cell::Cell)::Board
    if getcell(board, position) == OUT_OF_BOUNDS
        throw(OutOfBoundsException())
    end
    mutable_board = MMatrix(board)
    mutable_board[position.row, position.column] = cell
    Board(mutable_board)
end

"""
Get all empty cells except the one specified as a parameter.

Example, get all empty cells except the totem :

```
empty_cells_except(state.board, state.totem)
```
"""
empty_positions_except(board::Board, except::Position)::Vector{Position} = [
    Position(row, column) 
    for row in 1:BOARD_SIZE, 
        column in 1:BOARD_SIZE 
    if getcell(board, Position(row, column)) == EMPTY && Position(row, column) != except
]

"""
Get all valid place positions around the totem
"""
empty_positions_around(board::Board, totem::Position) = [
    totem + delta(direction)
    for direction in instances(Direction)
    if getcell(board, totem + delta(direction)) == EMPTY
]

function getscore(board::Board, totem::Position, player::Player)
    score = 0
    for direction in instances(Direction)
        cell = getcell(board, totem + delta(direction))
        isplayer(cell) && (score += cell)
    end
    player == WHITE ? score : - score
end

function player_pieces_around(board::Board, totem::Position, player::Player)
    count = 0
    for direction in instances(Direction)
        cell = getcell(board, totem + delta(direction))
        isplayer(cell, player) && (count += 1)
    end
    count
end

#################
# State functions
#################

export player_hand, current_player_hand

player_hand(state::State, player::Player)::Hand = player == WHITE ? state.white_hand : state.red_hand
current_player_hand(state::State) = player_hand(state, state.player)

#############
# State logic
#############

# Exceptions

export InvalidMoveException

struct InvalidMoveException <: Exception end
struct NotEnoughPieceException <: Exception end
struct InvalidPlacePositionException <: Exception end

# Logic

export isfinished, getscore, player_pieces_around, getwinner
export perform_action, move_totem, can_move_totem, valid_moves, valid_actions
export assert_can_place, valid_place_positions, empty_positions_around

isfinished(state::State) = isempty(valid_moves(state))

getscore(state::State, player::Player) = getscore(state.board, state.totem, player)
player_pieces_around(state::State, player::Player) = player_pieces_around(state.board, state.totem, player)

function getwinner(state::State)
    if isfinished(state)
        white_score = getscore(state, WHITE)
        white_score > 0 && return WHITE
        white_score < 0 && return RED
        white_pieces = player_pieces_around(state, WHITE)
        red_pieces = player_pieces_around(state, RED)
        white_pieces > red_pieces && return WHITE
        red_pieces > white_pieces && return RED
    end
    nothing
end

function valid_actions(state::State)::Vector{Action}
    actions = []
    for move in valid_moves(state)
        for place in valid_place_positions(state.board, move_totem(state, move))
            for value in 1:4
                if current_player_hand(state)[value] > 0
                    push!(actions, Action(move, place, value))
                end
            end
        end
    end
    actions
end

function perform_action(state::State, action::Action)::State
    # Assert
    new_totem = move_totem(state, action.move)
    assert_can_place(state, new_totem, action.place, action.value)
    # Create new state
    new_board = setcell(state.board, action.place, Cell(action.value, state.player))
    new_player = !state.player
    if state.player == WHITE
        new_white_hand = decrement(state.white_hand, action.value)
        new_red_hand = copy(state.red_hand)
    else
        new_white_hand = copy(state.white_hand)
        new_red_hand = decrement(state.red_hand, action.value)
    end
    State(new_board, new_totem, new_player, new_white_hand, new_red_hand)
end

function move_totem(state::State, direction::Direction)::Position
    new_totem = copy(state.totem)
    while true
        new_totem += delta(direction)
        cell = getcell(state.board, new_totem)
        if cell == EMPTY
            return new_totem
        elseif isplayer(cell, state.player)
            continue
        else
            throw(InvalidMoveException())
        end
    end
end

function can_move_totem(state::State, direction::Direction)::Bool
    try move_totem(state, direction) 
    catch _
        return false
    end
    return true
end

valid_moves(state::State)::Vector{Direction} = [
    direction
    for direction in instances(Direction)
    if can_move_totem(state, direction)
]

function assert_can_place(state::State, totem::Position, place::Position, value::PieceValue)
    if current_player_hand(state)[value] <= 0
        throw(NotEnoughPieceException())
    elseif !(place in valid_place_positions(state.board, totem))
        throw(InvalidPlacePositionException())
    end
end

"""
Get all valid place positions for a specific totem position
"""
function valid_place_positions(board::Board, totem::Position)::Vector{Position}
    around = empty_positions_around(board, totem)
    if !isempty(around)
        around
    else
        empty_positions_except(board, totem)
    end
end

end