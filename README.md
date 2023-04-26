# Yoxii engine in Julia

Simple Yoxii engine in Julia. It can 

- Create an initial Yoxii "State" (the board, totem position and player pieces)
- Print the state in a human-friendly format
- Validate transitions ("Plays") from a given state
- Compute a state by applying a play to a previous state

## Usage

```julia
include("Yoxii.jl")

# Create an initial state
s = Yoxii.initState()

# Print the state
Yoxii.printState(s)

# Perform a play (transition)
# Signature of a Play is (move::Direction, place::Coords, value::Int)
# where 'move' is the direction where the totem will move
#       'place' is the coordinates where the piece will be placed
#       'value' is the value of the piece to place
s = Yoxii.transition(s, Yoxii.Play(Yoxii.UP, (2, 4), 3))
```

Example of printing a state. White pieces are in parenthesis, whereas red pieces are in diamonds.

```
Current player : Red
White pieces : [4, 5, 3, 3]
Red pieces   : [3, 5, 5, 3]
        *---*---*---*
        |   |   |   |
    *---*---*---*---*---*
    |<1>|(1)|(3)|   |   |
*---*---*---*---*---*---*---*
|   |<1>|   |   |   |   |   |
*---*---*---*---*---*---*---*
| * |(3)|   |   |   | . |   |
*---*---*---*---*---*---*---*
|   |   |   |   |   |   |   |
*---*---*---*---*---*---*---*
    |   |   | . |   |   |
    *---*---*---*---*---*
        |   |   |   |
        *---*---*---*

```

Invalid transitions will throw errors :

```julia
s = Yoxii.transition(s, Yoxii.Play(Yoxii.UP_RIGHT, (4, 2), 3))
```

```
ERROR: Main.Yoxii.CannotMoveException()
Stacktrace:
 [1] _tryCanMove(s::Main.Yoxii.State, move::Main.Yoxii.Direction)
   @ Main.Yoxii /mnt/e/Projets/yoxii/test.jl:77
 [2] transition(s::Main.Yoxii.State, p::Main.Yoxii.Play)
   @ Main.Yoxii /mnt/e/Projets/yoxii/test.jl:42
 [3] top-level scope
   @ REPL[331]:1
```

##