module Yoxii
const EMPTY = 0
const OUT_OF_BOUNDS = 9

Board = Matrix{Int}
Coords = Tuple{Int,Int}

@enum Direction UP UP_RIGHT RIGHT DOWN_RIGHT DOWN DOWN_LEFT LEFT UP_LEFT

struct Play
    move::Direction
    place::Coords
    value::Int
end

struct State
    board::Board
    totem::Coords
    white_to_play::Bool
    white_pieces::Vector{Int}
    red_pieces::Vector{Int}
end

function initState()::State
    board = zeros(Int, 7, 7)
    board[1, 1] = OUT_OF_BOUNDS
    board[1, 2] = OUT_OF_BOUNDS
    board[2, 1] = OUT_OF_BOUNDS
    board[end, 1] = OUT_OF_BOUNDS
    board[end, 2] = OUT_OF_BOUNDS
    board[end-1, 1] = OUT_OF_BOUNDS
    board[end, end] = OUT_OF_BOUNDS
    board[end, end-1] = OUT_OF_BOUNDS
    board[end-1, end] = OUT_OF_BOUNDS
    board[1, end] = OUT_OF_BOUNDS
    board[1, end-1] = OUT_OF_BOUNDS
    board[2, end] = OUT_OF_BOUNDS
    return State(board, (4, 4), true, [5, 5, 5, 3], [5, 5, 5, 3])
end

function transition(s::State, p::Play)::State
    newTotem = _tryCanMove(s, p.move)
    _tryCanPlace(s, newTotem, p.place, p.value)
    # No exception, proceed
    (r, c) = p.place
    newBoard = copy(s.board)
    newBoard[r, c] = s.white_to_play ? p.value : -p.value
    newWhitePieces = copy(s.white_pieces)
    newRedPieces = copy(s.red_pieces)
    if (s.white_to_play)
        newWhitePieces[p.value] -= 1
    else
        newRedPieces[p.value] -= 1
    end
    return State(newBoard, newTotem, !s.white_to_play, newWhitePieces, newRedPieces)
end

function printState(s::State)
    println("Current player : $(_playerStr(s))")
    println("White pieces : $(s.white_pieces)")
    println("Red pieces   : $(s.red_pieces)")
    _printBoard(s.board, s.totem)
end

struct MultipleTotemException <: Exception end
struct UnknownCellException <: Exception end
struct CannotMoveException <: Exception end
struct NotEnoughPiecesException <: Exception end
struct InvalidPlacementException <: Exception end

function _tryCanMove(s::State, move::Direction)::Coords
    d = _directionDelta(move)
    c = s.totem
    while true
        c = _addCoords(c, d)
        if _oob(s.board, c) || _otherPlayerHasCell(s, c)
            throw(CannotMoveException())
        elseif _empty(s.board, c)
            return c
        elseif !_currentPlayerHasCell(s, c)
            throw(UnknownCellException())
        end
    end
end

function _freeSpaces(b::Board, totem::Coords)::Vector{Coords}
    list = []
    for d in instances(Direction)
        if (_oob(b, totem, d))
            continue
        end
        c = _addCoords(totem, _directionDelta(d))
        if _empty(b, c)
            push!(list, c)
        end
    end
    return list
end

function _tryCanPlace(s::State, totem::Coords, p::Coords, v::Int)
    if _currentPlayerPieces(s)[v] <= 0
        throw(NotEnoughPiecesException())
    end
    free = _freeSpaces(s.board, totem)
    if size(free, 1) > 0
        for space in free
            if space == p
                return
            end
        end
        throw(InvalidPlacementException())
    end
    if !_empty(s.board, p)
        throw(InvalidPlacementException())
    end
end

function _printBoard(b::Board, totem::Coords)
    sup = ""
    for c = 1:size(b, 2)
        sup = string(sup, _cellStrUp(b, 1, c))
    end
    println(sup)
    for r = 1:size(b, 1)
        smid = ""
        sdown = ""
        for c = 1:size(b, 2)
            smid = string(smid, _cellStrMid(b, r, c, totem))
            sdown = string(sdown, _cellStrDown(b, r, c))
        end
        println(smid)
        println(sdown)
    end
end

_currentPlayerPieces(s::State)::Vector{Int} = s.white_to_play ? s.white_pieces : s.red_pieces
_addCoords((r1, c1)::Coords, (r2, c2)::Coords)::Coords = (r1 + r2, c1 + c2)

function _directionDelta(d::Direction)::Coords
    if d == UP
        return (-1, 0)
    elseif d == UP_RIGHT
        return (-1, 1)
    elseif d == RIGHT
        return (0, 1)
    elseif d == DOWN_RIGHT
        return (1, 1)
    elseif d == DOWN
        return (1, 0)
    elseif d == DOWN_LEFT
        return (1, -1)
    elseif d == LEFT
        return (0, -1)
    elseif d == UP_LEFT
        return (-1, -1)
    end
end

_playerStr(s::State) = s.white_to_play ? "White" : "Red"

_cellInPlayerRange(v::Int, white::Bool) = (white && (1 <= v <= 4)) || (!white && -4 <= v <= -1)

_playerHasCell(b::Board, r::Int, c::Int, white::Bool) = !_oob(b, r, c) && _cellInPlayerRange(b[r, c], white)
_playerHasCell(b::Board, (r, c)::Coords, white::Bool) = _playerHasCell(b, r, c, white)
_currentPlayerHasCell(s::State, r::Int, c::Int) = _playerHasCell(s.board, r, c, s.white_to_play)
_currentPlayerHasCell(s::State, (r, c)::Coords) = _currentPlayerHasCell(s, r, c)
_otherPlayerHasCell(s::State, r::Int, c::Int) = _playerHasCell(s.board, r, c, !s.white_to_play)
_otherPlayerHasCell(s::State, (r, c)::Coords) = _otherPlayerHasCell(s, r, c)

_empty(b::Board, (r, c)::Coords)::Bool = b[r, c] == EMPTY

function _oob(b::Board, r::Int, c::Int, d::Direction)::Bool
    (dr, dc) = _directionDelta(d)
    (tr, tc) = (r + dr, c + dc)
    if tr < 1 || tc < 1 || tr > size(b, 1) || tc > size(b, 2)
        return true
    end
    return b[tr, tc] == OUT_OF_BOUNDS
end

_oob(b::Board, r::Int, c::Int)::Bool = b[r, c] == OUT_OF_BOUNDS
_oob(b::Board, (r, c)::Coords)::Bool = _oob(b, r, c)
_oob(b::Board, (r, c)::Coords, d::Direction)::Bool = _oob(b, r, c, d)

function _cellStrUp(b::Board, r::Int, c::Int)::String
    if !_oob(b, r, c) || !_oob(b, r, c, UP)
        return c < size(b, 2) ? "*---" : "*---*"
    end
    s = !_oob(b, r, c, UP_LEFT) || !_oob(b, r, c, LEFT) ? "*   " : "    "
    if c == size(b, 2)
        return string(s, !_oob(b, r, c, UP_RIGHT) ? "*" : " ")
    end
    return s
end

_isCellHoshi(b::Board, r::Int, c::Int)::Bool = size(b) == (7, 7) && ((r, c) == (2, 4) || (r, c) == (4, 6) || (r, c) == (6, 4) || (r, c) == (4, 2))

function _cellStrPiece(b::Board, r::Int, c::Int, totem::Coords)::String
    if b[r, c] == OUT_OF_BOUNDS
        return "   "
    elseif (r, c) == totem
        return " * "
    elseif b[r, c] == EMPTY
        return _isCellHoshi(b, r, c) ? " . " : "   "
    elseif b[r, c] < 0
        return "<$(abs(b[r, c]))>"
    else
        return "($(b[r, c]))"
    end
end

function _cellStrMid(b::Board, r::Int, c::Int, totem::Coords)::String
    s = !_oob(b, r, c) || !_oob(b, r, c, LEFT) ? "|" : " "
    s = string(s, _cellStrPiece(b, r, c, totem))
    if c == size(b, 2)
        return string(s, !_oob(b, r, c) || !_oob(b, r, c, RIGHT) ? "|" : " ")
    end
    return s
end

#fonction _cellStrDown

function _cellStrDown(b::Board, r::Int, c::Int)::String
    if !_oob(b, r, c) || !_oob(b, r, c, DOWN)
        return c < size(b, 2) ? "*---" : "*---*"
    end
    s = !_oob(b, r, c, DOWN_LEFT) || !_oob(b, r, c, LEFT) ? "*   " : "    "
    if c == size(b, 2)
        return string(s, !_oob(b, r, c, DOWN_RIGHT) ? "*" : " ")
    end
    return s
end
end