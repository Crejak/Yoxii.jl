module GameTest

using Yoxii.Game
using StaticArrays
using Test, ..TestUtils
    
const DEFAULT_BOARD = SMatrix{7, 7, Int8}([
    9 9 0 0 0 9 9;
    9 0 0 0 0 0 9;
    0 0 0 0 0 0 0;
    0 0 0 0 0 0 0;
    0 0 0 0 0 0 0;
    9 0 0 0 0 0 9;
    9 9 0 0 0 9 9
])

@testset "Game" begin
    @testset "Hand" begin
        @test decrement(INITIAL_HAND, PieceValue(1)) == SVector{4}([4, 5, 5, 3])
    end

    @testset "Cell" begin
        @test Cell(PieceValue(3), WHITE) == 3
        @test Cell(PieceValue(1), RED) == -1
        @test isplayer(Cell(2))
        @test isplayer(Cell(-4))
        @test isplayer(Cell(5)) == false
        @test isplayer(Cell(0)) == false
        @test isplayer(Cell(4), WHITE)
        @test isplayer(Cell(-2), RED)
    end

    @testset "Position" begin
        @test Position(1, 0) == Position(1, 0)
        @test Position(0, 1) != Position(1, 0)
        @test delta(NORTH) == Position(-1, 0)
        @test copy(Position(4, 7)) == Position(4, 7)
        @test Position(0, 0) + Position(1, 2) == Position(1, 2)
        @test Position(4, 6) + Position(-1, 1) == Position(3, 7)
    end

    @testset "Board" begin

        @test init_board() == DEFAULT_BOARD
        @test getcell(DEFAULT_BOARD, Position(4, 4)) == EMPTY
        @test getcell(DEFAULT_BOARD, Position(6, 7)) == OUT_OF_BOUNDS
        @test getcell(DEFAULT_BOARD, Position(-8, 12)) == OUT_OF_BOUNDS

        @test setcell(DEFAULT_BOARD, Position(3, 6), Cell(-3)) == SMatrix{7, 7, Int8}([
            9 9 0 0 0 9 9;
            9 0 0 0 0 0 9;
            0 0 0 0 0 -3 0;
            0 0 0 0 0 0 0;
            0 0 0 0 0 0 0;
            9 0 0 0 0 0 9;
            9 9 0 0 0 9 9
        ])
        @test_throws OutOfBoundsException setcell(DEFAULT_BOARD, Position(1, 1), Cell(4))
        @test_throws OutOfBoundsException setcell(DEFAULT_BOARD, Position(-8, 12), Cell(2))
        
        @test length(empty_positions_except(DEFAULT_BOARD, Position(4, 4))) == 36
        @test compare_unsorted(empty_positions_except(Board([
            9  9  1  0  3  9  9;
            9  1 -3 -4  0  4  9;
           -1  1  0 -2  2 -4  2;
            2  0 -2  0 -3 -3  3;
            1  0  4  0  1  2  0;
            9 -1  0 -1 -1  1  9;
            9  9  1  2  0  9  9
        ]), Position(4, 4)),  [
            Position(1, 4), Position(2, 5), Position(3, 3), Position(4, 2),
            Position(5, 2), Position(5, 4), Position(5, 7), Position(6, 3),
            Position(7, 5)
        ])

        @test compare_unsorted(empty_positions_around(DEFAULT_BOARD, Position(4, 4)), [
            Position(3, 4), Position(3, 5), Position(4, 5), Position(5, 5),
            Position(5, 4), Position(5, 3), Position(4, 3), Position(3, 3)
        ]);
        @test compare_unsorted(empty_positions_around(DEFAULT_BOARD, Position(2, 2)), [
            Position(1, 3), Position(2, 3), Position(3, 3), Position(3, 2),
            Position(3, 1)
        ]);
        @test compare_unsorted(empty_positions_around(DEFAULT_BOARD, Position(7, 5)), [
            Position(6, 5), Position(6, 6), Position(7, 4), Position(6, 4)
        ]);
        @test compare_unsorted(empty_positions_around(Board([
            9  9  1  0  3  9  9;
            9  1 -3 -4  0  4  9;
           -1  1  0 -2  2 -4  2;
            2  0 -2  0 -3 -3  3;
            1  0  4  0  1  2  0;
            9 -1  0 -1 -1  1  9;
            9  9  1  2  0  9  9
        ]), Position(4, 4)), [
            Position(3, 3), Position(5, 4)
        ]);
    end

    @testset "State" begin
        @test init_state().board == DEFAULT_BOARD
        @test init_state().totem == Position(4, 4)
        @test init_state().player == WHITE
        @test init_state().white_hand == INITIAL_HAND
        @test init_state().red_hand == INITIAL_HAND

        @test player_hand(State(
            DEFAULT_BOARD,
            Position(4, 4),
            WHITE, 
            SVector{4}([1, 2, 3, 1]), 
            SVector{4}([3, 4, 1, 1])
        ), WHITE) == SVector{4}([1, 2, 3, 1])
        @test player_hand(State(
            DEFAULT_BOARD,
            Position(4, 4),
            WHITE, 
            SVector{4}([1, 2, 3, 1]), 
            SVector{4}([3, 4, 1, 1])
        ), RED) == SVector{4}([3, 4, 1, 1])

        @test current_player_hand(State(
            DEFAULT_BOARD,
            Position(4, 4),
            WHITE, 
            SVector{4}([1, 2, 3, 1]), 
            SVector{4}([3, 4, 1, 1])
        )) == SVector{4}([1, 2, 3, 1])
        @test current_player_hand(State(
            DEFAULT_BOARD,
            Position(4, 4),
            RED, 
            SVector{4}([1, 2, 3, 1]), 
            SVector{4}([3, 4, 1, 1])
        )) == SVector{4}([3, 4, 1, 1])
    end

    @testset "Logic" begin
        @test isfinished(init_state()) == false
        @test isfinished(State(Board([
                9  9  0  1  0  9  9;
                9  0 -1  1  1  1  9;
                0  0 -1  0  0  0  0;
                0  0  0  0 -1  0  0;
                0  0  0  0  0  0  0;
                9  0  0  0  0  0  9;
                9  9  0  0  0  9  9
            ]),
            Position(1, 5),
            RED,
            SVector{4}([1, 5, 5, 3]), 
            SVector{4}([1, 5, 5, 3])
        )) == true
        @test isfinished(State(Board([
                9  9  0  1  0  9  9;
                9  0 -1  1  1  1  9;
                0  0 -1  0  0  0  0;
                0  0  0  0 -1  0  0;
                0  0  0  0  0  0  0;
                9  0  0  0  0  0  9;
                9  9  0  0  0  9  9
            ]),
            Position(1, 5),
            WHITE,
            SVector{4}([1, 5, 5, 3]), 
            SVector{4}([1, 5, 5, 3])
        )) == false

        @test length(valid_actions(init_state())) == 256
        @test length(valid_actions(State(Board([
                9  9  0  1  0  9  9;
                9  0 -1  1  1  1  9;
                0  0 -1  0  0  0  0;
                0  0  0  0 -1  0  0;
                0  0  0  0  0  0  0;
                9  0  0  0  0  0  9;
                9  9  0  0  0  9  9
            ]),
            Position(1, 5),
            WHITE,
            SVector{4}([1, 5, 5, 3]), 
            SVector{4}([1, 5, 5, 3])
        ))) == 32
        @test Action(WEST, Position(2, 2), 4) in valid_actions(State(Board([
                9  9  0  1  0  9  9;
                9  0 -1  1  1  1  9;
                0  0 -1  0  0  0  0;
                0  0  0  0 -1  0  0;
                0  0  0  0  0  0  0;
                9  0  0  0  0  0  9;
                9  9  0  0  0  9  9
            ]),
            Position(1, 5),
            WHITE,
            SVector{4}([1, 5, 5, 3]), 
            SVector{4}([1, 5, 5, 3])
        ))
        @test (Action(WEST, Position(2, 3), 4) in valid_actions(State(Board([
                9  9  0  1  0  9  9;
                9  0 -1  1  1  1  9;
                0  0 -1  0  0  0  0;
                0  0  0  0 -1  0  0;
                0  0  0  0  0  0  0;
                9  0  0  0  0  0  9;
                9  9  0  0  0  9  9
            ]),
            Position(1, 5),
            WHITE,
            SVector{4}([1, 5, 5, 3]), 
            SVector{4}([1, 5, 5, 3])
        ))) == false
    end
end

end