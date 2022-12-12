# zig-sudoku

> Note: this project is a Work in Progress.

## Goals

- [X] data representation of the sudoku board
- [X] visual representation
- [X] grid system to identify cells and make moves
- [X] user can input numbers and erase numbers (but cannot overwrite those from the initial board)
- [X] load puzzle from file
- [ ] generate printable document from a sudoku
- [ ] player-supplied notes per-cell (scratchpad)
- [ ] warn player on illegal moves
- [ ] congratulate player when the sudoku is solved
- [ ] brute-force (guess + backtrack) sudoku solver
- [ ] generate random sudokus
- [ ] human-readable random number seed (or classification) of a sudoku board
- [ ] generate flag for "fun" sudokus
- [ ] generate flag for entertainment sudokus (must only be one solution)
- [ ] generate flag for difficulty level
- [ ] user can specify their own seed
- [ ] support n = 2 sudoku boards
- [ ] support n > 3 sudoku boards
- [ ] logic-based sudoku solver using human sudoku-solving techniques (like hidden double, hidden triple, swordfish, jellyfish, etc.)
- [ ] wasm api for sudoku engine (generate sudokus, track board state and validate moves, solve sudokus)
- [ ] expose and visualize internal data structures like information concerning move validation as an accessibility option
- [ ] raw terminal UI instead of REPL UI
