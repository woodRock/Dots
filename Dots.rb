#!/usr/bin/ruby

require 'ruby2d'
load 'lib.rb'
include Lib

# Game board consists on dims x dims board.
dims = 3

# Starts with no lines drawn.
is_line = Array.new(number_of_lines(dims)) { false }
squares = { -1 => Square.new(size: 0) }
lines = {}

# Move counter. Keeps track of turns.
counter = 0

# Flag for which square is chosen. Defaults to -1 for none.
current = -1

p1_squares = []
p2_squares = []

board(is_line, dims, squares, lines)
game_won = false

p1_col = 'orange'
p2_col = 'purple'
p1_hover_col = '#FFF2E5'
p2_hover_col = '#F5E5FF'

def reset
  # TODO: implement me!
end

# Mouse input handler
on :mouse_move do |e|
  not_on_screen = true
  squares.keys.each do |s|
    # Check overlap in bounding between square and cursor.
    cursor_on = squares[s].contains?(e.x, e.y)
    current = s if cursor_on
    not_on_screen &= !cursor_on
  end

  # Use -1 as flag for mouse being offscreen.
  current = -1 if not_on_screen
end

# Event handler for user input.
on :key_down do |k|
  # Handle macros, quit and reset.
  close if k.key.eql? 'q'
  reset if k.key.eql? 'r'

  # WASD correspond to directions in vector space.
  input = { 'w' => 0, 'a' => 1, 'd' => 2, 's' => 3 }

  # Validate user input.
  valid_key = input.keys.include? k.key

  # Ignore input if cursor is offscreen.
  next if current == -1

  # Increment game counter. This is used to determine which player's turn it is.
  counter += make_move(current, dims, k.key, input, is_line, counter, p1_squares, p2_squares) if valid_key

  # Total squares is combination of both player scores.
  squares_drawn = p1_squares.length + p2_squares.length

  # Has move won the game.
  game_won = true if is_game_over?(squares_drawn, dims)
end

# Update handler, runs each click of the game loop.
update do
  # Colour in squares that have been won.
  squares.keys.each do |s|
    next if s == -1

    squares[s].color = 'white'
    square_indexes = is_square?(square_indexes(s, dims), is_line)
    p1 = p1_squares.include? s
    p2 = p2_squares.include? s
    squares[s].color = p1_col if square_indexes && p1
    squares[s].color = p2_col if square_indexes && p2
  end

  # Hover animation.
  unless is_square?(square_indexes(current, dims), is_line)
    squares[current].color = is_p1_move?(counter) ? p1_hover_col : p2_hover_col
  end

  draw_lines(is_line, lines)

  # Show gameover screen, i.e. all squares turn winning players colour.
  game_over(p1_col, p2_col, p1_squares, p2_squares, squares) if game_won
end

show
