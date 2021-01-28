#! /usr/bin/ruby

require 'ruby2d'

module Lib
  def number_of_lines(dims)
      return 2*(dims**2 + dims)
  end

  def board(is_line, dims, squares, lines)
      pad = 15
      sq_size = 50
      set title: 'Dots and Boxes'
      set height: pad+dims*sq_size
      set width: pad+dims*sq_size
      set background: 'white'
      set resizable: false
      dir = { "up"=>0,"left"=>1,"right"=>2,"down"=>3 }
      off = 0
      count = 0
      (0...dims).each do |y|
          (0...dims).each do |x|
              off = 5 if (x==0 && y==0)
              _x = off+x*sq_size
              _y = off+y*sq_size
              squares[count] = Square.new(size: sq_size, color: 'green', x: _x, y: _y)
              count += 1
          end
      end
      squares.keys.each do |s|
          next if s == -1
          lines_in_square = square_indexes(s, dims)
          l_map = {}
          _x = squares[s].x
          _y = squares[s].y
          off = pad/2
          l_map["up"] = [ _x+off, _y, sq_size - off, off ]
          l_map["left"] = [ _x, _y+off, off, sq_size-off ]
          l_map["right"] = [ _x+sq_size, _y+off, off, sq_size-off ]
          l_map["down"] = [ _x, _y+sq_size, sq_size-off, off ]
          dir.keys.each do |d|
              rect = Rectangle.new(x:l_map[d][0], y:l_map[d][1], width:l_map[d][2], height:l_map[d][3], color:'white')
              lines[lines_in_square[dir[d]]] = rect
          end
      end
  end

  def square_indexes(num, dims)
      return - 1 if num < 0
      c = num + ((num-(num%dims))/dims)*(dims+1)
      return [0+c, dims+c, dims+1+c, dims*2+1+c]
  end

  def index_of_line(square_indexes, dir, directions)
      return square_indexes[directions[dir]]
  end

  def add_line(line, is_line)
      valid = !is_line[line]
      is_line[line] = true if valid
      return valid
  end

  def draw_lines(is_line, lines)
      is_line.each_with_index do |line, i|
          color = 'black' if line
          color = 'white' if !line
          lines[i].color = color
      end
  end

  def neighbour(current, dir, dims)
      return current-1 if has_left?(current, dims) if dir.eql? "a"
      return current+1 if has_right?(current, dims) if dir.eql? "d"
      return current - dims if (current - dims >= 0) if dir.eql? "w"
      return current + dims if (current + dims < dims**2) if dir.eql? "s"
      return -1
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
      after_neighbour = is_square?(square_indexes(neighbour,dims), is_line)
      scored = !before && after
      neighbour_scored = !before_neighbour && after_neighbour
      p1_move = is_p1_move?(counter)
      p1 << current if scored && p1_move
      p1 << neighbour if neighbour_scored && p1_move
      p2 << current if scored && !p1_move
      p2 << neighbour if neighbour_scored && !p1_move
      return 0 if scored or neighbour_scored or !valid
      return 1
  end

  def game_over(p1_col, p2_col, p1_squares, p2_squares, squares)
      p1_won = p1_squares.length > p2_squares.length
      p2_won = p1_squares.length < p2_squares.length
      draw = p1_squares.length == p2_squares.length
      color = p1_col if p1_won
      color = p2_col if p2_won
      color = 'gray' if draw
      squares.keys.each { |s| squares[s].color = color }
  end

  def is_square?(square_indexes, is_line)
      return false if square_indexes == -1
      res = true
      square_indexes.each { |i| res &= is_line[i] }
      return res
  end

  def is_valid_move?(line, is_line)
      return !is_line[line]
  end

  def is_p1_move?(counter)
      return counter % 2 == 0
  end

  def has_left?(current, dims)
      return (square_indexes(current - 1, dims)[0] == square_indexes(current, dims)[0] - 1 && current - 1 >= 0)
  end

  def has_right?(current, dims)
      return (square_indexes(current + 1, dims)[0] == square_indexes(current, dims)[0] + 1 && current + 1 <= dims**2)
  end
end

include Lib

dims = 10
is_line = Array.new(number_of_lines(dims)) { false }
squares = { -1 => Square.new(size:0) } # no square_indexes selected
lines = {}
counter = 0
current = -1
p1_squares = []
p2_squares = []
board(is_line, dims, squares, lines)
game_won = false
p1_col = 'orange'
p2_col = 'purple'
p1_hover_col = '#FFF2E5'
p2_hover_col = '#F5E5FF'

def reset()

end

on :mouse_move do |e|
    not_on_screen = true
    squares.keys.each do |s|
        cursor_on = squares[s].contains?(e.x, e.y)
        current = s if cursor_on
        not_on_screen &= !cursor_on
    end
    current = -1 if not_on_screen
end

on :key_down do |k|
    close if k.key.eql? "q"
    reset() if k.key.eql? "r"
    input = { "w"=>0,"a"=>1,"d"=>2,"s"=>3 }
    valid_key = input.keys.include? k.key
    next if current == -1
    counter += make_move(current, dims, k.key, input, is_line, counter, p1_squares, p2_squares) if valid_key
    squares_drawn = p1_squares.length+p2_squares.length
    game_won = true if (squares_drawn >= dims*dims)
end

update do
    squares.keys.each do |s|
        next if s == -1
        squares[s].color = 'white'
        square_indexes = is_square?(square_indexes(s, dims), is_line)
        p1 = p1_squares.include? s
        p2 = p2_squares.include? s
        squares[s].color = p1_col if square_indexes && p1
        squares[s].color = p2_col if square_indexes && p2
    end
    p1_move = is_p1_move?(counter)
    not_square = !is_square?(square_indexes(current, dims), is_line)
    squares[current].color = p1_hover_col if not_square && p1_move
    squares[current].color = p2_hover_col if not_square && !p1_move
    draw_lines(is_line, lines)
    game_over(p1_col, p2_col, p1_squares, p2_squares, squares) if game_won
end

show
