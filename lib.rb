#! /usr/bin/ruby

require 'ruby2d'

module Lib
  def board(_is_line, dims, squares, lines)
    pad = 15
    sq_size = 50

    # Generic window properties
    set title: 'Dots and Boxes'
    set height: pad + dims * sq_size
    set width: pad + dims * sq_size
    set background: 'white'
    set resizable: false

    # Directions map to vectors.
    dir = { 'up' => 0, 'left' => 1, 'right' => 2, 'down' => 3 }

    # Offset
    off = 0
    count = 0

    # Initialize all the squares.
    (0...dims).each do |y|
      (0...dims).each do |x|
        off = 5 if x.zero? && y.zero? # 5px padding from top and left.
        _x = off + x * sq_size
        _y = off + y * sq_size
        squares[count] = Square.new(size: sq_size, color: 'green', x: _x, y: _y)
        count += 1
      end
    end

    # Fill in the squares.
    squares.keys.each do |s|
      # No squares have been won yet.
      next if s == -1

      lines_in_square = square_indexes(s, dims)

      # Retrieve x and y coordinates (base) for the square.
      _x = squares[s].x
      _y = squares[s].y
      off = pad / 2

      # Compute envelope for each line.
      l_map = {}
      l_map['up'] = [_x + off, _y, sq_size - off, off]
      l_map['left'] = [_x, _y + off, off, sq_size - off]
      l_map['right'] = [_x + sq_size, _y + off, off, sq_size - off]
      l_map['down'] = [_x + off, _y + sq_size, sq_size - off, off]

      # Work out location of the lines in each direction (i.e up, left, right, down)
      dir.keys.each do |d|
        # A line is rectangle.
        rect = Rectangle.new(
          x: l_map[d][dir['up']],
          y: l_map[d][dir['left']],
          width: l_map[d][dir['right']],
          height: l_map[d][dir['down']],
          color: 'white' # By default each line is white.
        )
        # Store the line in the lines array.
        lines[lines_in_square[dir[d]]] = rect
      end
    end
  end

  # Returns the index positions that correspond to a given square.
  # Given a dims x dims board, the index positions can be derived as follows.
  def square_indexes(num, dims)
    # Check if the square is valid.
    return - 1 if num.negative? || num > dims**2 - 1

    c = num + ((num - (num % dims)) / dims) * (dims + 1)
    [c, dims + c, dims + 1 + c, dims * 2 + 1 + c]
  end

  # Returns the index positions that correspond to a given line.
  # Given the list of square indexes and direction, and direction to vector mapping.
  def index_of_line(square_indexes, dir, directions)
    # Retrieve the index of a line.
    square_indexes[directions[dir]]
  end

  def add_line(line, is_line)
    valid = !is_line[line]
    is_line[line] = true if valid
    valid # See if move was successful.
  end

  def draw_lines(is_line, lines)
    is_line.each_with_index do |line, i|
      # If line has been filled, draw it black. Otherwise, white.
      color = line ? 'black' : 'white'
      lines[i].color = color
    end
  end

  def neighbour(current, dir, dims)
    return current - 1 if dir.eql?('a') && has_left?(current, dims)
    return current + 1 if dir.eql?('d') && has_right?(current, dims)
    return current - dims if dir.eql?('w') && (current - dims >= 0)
    return current + dims if dir.eql?('s') && (current + dims < dims**2)

    -1 # No neighbour.
  end

  def make_move(current, dims, key, map, is_line, counter, p1, p2)
    return 0 if current == -1

    lines = square_indexes(current, dims)
    line = index_of_line(lines, key, map)
    valid = is_valid_move?(line, is_line)
    before = is_square?(square_indexes(current, dims), is_line)
    neighbour = neighbour(current, key, dims)
    before_neighbour = is_square?(square_indexes(neighbour, dims), is_line)
    add_line(line, is_line)
    after = is_square?(square_indexes(current, dims), is_line)
    after_neighbour = is_square?(square_indexes(neighbour, dims), is_line)
    scored = !before && after
    neighbour_scored = !before_neighbour && after_neighbour
    p1_move = is_p1_move?(counter)
    p1 << current if scored && p1_move
    p1 << neighbour if neighbour_scored && p1_move
    p2 << current if scored && !p1_move
    p2 << neighbour if neighbour_scored && !p1_move
    return 0 if scored or neighbour_scored or !valid

    1 # Regular move - valid and no squares won - now next players turn.
  end

  def game_over(p1_col, p2_col, p1_squares, p2_squares, squares)
    # Compute result of the game.
    p1_won = p1_squares.length > p2_squares.length
    p2_won = p1_squares.length < p2_squares.length
    draw = p1_squares.length == p2_squares.length

    # Result is shown as a color.
    color = p1_col if p1_won
    color = p2_col if p2_won
    color = 'gray' if draw

    # All squares turn the game result colour above.
    squares.keys.each { |s| squares[s].color = color }
  end

  def is_square?(square_indexes, is_line)
    # Handle invalid square.
    return false if square_indexes == -1

    res = true
    # See if all the lines of a square are filled.
    square_indexes.each { |i| res &= is_line[i] }
    res # True if all filled, false otherwise.
  end

  def is_valid_move?(line, is_line)
    # Move is not valid if a line does not exist.
    !is_line[line]
  end

  def is_p1_move?(counter)
    # Game counter starts at 0. If even, player 1's turn.
    counter.even?
  end

  def has_left?(current, dims)
    # Checks if a square has a left neighbour.
    (square_indexes(current - 1, dims)[0] == square_indexes(current, dims)[0] - 1 && current - 1 >= 0)
  end

  def has_right?(current, dims)
    # Checks if a square has a right neighbour.
    (square_indexes(current + 1, dims)[0] == square_indexes(current, dims)[0] + 1 && current + 1 <= dims**2)
  end

  def is_game_over?(squares_drawn, dims)
    # Game over when all squares are filled.
    (squares_drawn >= dims * dims)
  end

  def number_of_lines(dims)
    # Return the total number of lines.
    2 * (dims**2 + dims)
  end
end
