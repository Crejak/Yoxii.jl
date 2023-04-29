# Julia Yoxii game

Simple Yoxii game engine in Julia. The goal is to use it for reinforcement learning.

## Usage

First, you need to load the dependencies :

```julia
# Inside Pkg REPL
activate .
instantiate
```

### Using the game engine

```julia
# Game objects and logic are defined in the Game submodule
using Yoxii.Game

# Create an initial state
s = init_state()

# Play a move : move the totem in the NORTH / UP direction, place a piece with the value 3 at
# the cell located in row 2, column 4
s = perform_action(s, Action(NORTH, Position(2, 4), 3))

# Check if the game is finished
isfinished(s)

# Get the winner
getwinner(s)
```

### Using the AlphaZero wrapper

```julia
# Import the AlphaZero library
using AlphaZero

# The wrapper for AlphaZero.jl is defined in the AZWrapper submodule
using Yoxii.AZWrapper

# Run the test script
AlphaZero.Scripts.test_game(YoxiiGameSpec())

```

## TODO

- Machine learning
  - [ ] Ask the mathematicians how the f*ck I can get AlphaZero to work correctly
- Testing
  - [ ] Complete the unit test coverage
  - [ ] Add integration tests for whole games
- IO
  - [ ] Pretty print the state
  - [ ] Parse / format actions to / from string
  - [ ] CLI for playing games interactively
- Cleaning
  - [ ] Only export what need to be public
  - [ ] Use more consistent naming
  - [ ] See how I can make the code more idiomatic / nice to read
  - [ ] Add documentation comments
- Optimization
  - [ ] Benchmark ??? I have to idea if this code is efficient or not (probably not)
  - [ ] Maybe mutate the state instead of copying it every time ?
