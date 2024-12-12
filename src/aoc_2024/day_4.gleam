import aoc_2024/matrix.{type Matrix}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder

// Day 4

pub opaque type Token {
  X
  M
  A
  S
}

type Dir {
  North
  NorthEast
  East
  SouthEast
  South
  SouthWest
  West
  NorthWest
}

pub fn parse(input: String) -> Matrix(Token) {
  input
  |> string.split("\n")
  |> list.map(fn(l) {
    l
    |> string.split("")
    |> list.map(fn(c) {
      case c {
        "X" -> X
        "M" -> M
        "A" -> A
        "S" -> S
        _ -> panic as "invalid token"
      }
    })
  })
  |> matrix.from_list_of_lists()
}

pub fn pt_1(matrix: Matrix(Token)) {
  yielder.range(0, matrix.width - 1)
  |> yielder.flat_map(fn(x) {
    yielder.range(0, matrix.height - 1)
    |> yielder.map(fn(y) { #(x, y) })
  })
  |> yielder.map(fn(c) { count_xmas_occurrences(c, matrix) })
  |> yielder.fold(0, int.add)
}

pub fn pt_2(matrix: Matrix(Token)) {
  yielder.range(0, matrix.width - 1)
  |> yielder.flat_map(fn(x) {
    yielder.range(0, matrix.height - 1)
    |> yielder.map(fn(y) { #(x, y) })
  })
  |> yielder.filter(fn(c) { x_mas_occurs(c, matrix) })
  |> yielder.length()
}

// Auxiliaries Part 1

fn count_xmas_occurrences(coords: #(Int, Int), matrix: Matrix(Token)) -> Int {
  [North, NorthEast, East, SouthEast, South, SouthWest, West, NorthWest]
  |> list.count(fn(dir) { occurrs_in_dir(coords, matrix, dir) })
}

fn occurrs_in_dir(c1: #(Int, Int), matrix: Matrix(Token), dir: Dir) -> Bool {
  let tiles = {
    use t1 <- result.try(matrix.get(matrix, c1.0, c1.1))
    use #(c2, t2) <- result.try(get_in_dir(c1, matrix, dir))
    use #(c3, t3) <- result.try(get_in_dir(c2, matrix, dir))
    use #(_, t4) <- result.try(get_in_dir(c3, matrix, dir))
    Ok([t1, t2, t3, t4])
  }

  case tiles {
    Ok([X, M, A, S]) -> True
    _ -> False
  }
}

// Auxiliaries Part 2

fn x_mas_occurs(coords: #(Int, Int), matrix: Matrix(Token)) -> Bool {
  let tiles = {
    use t1 <- result.try(matrix.get(matrix, coords.0, coords.1))
    use #(_, t2) <- result.try(get_in_dir(coords, matrix, NorthWest))
    use #(_, t3) <- result.try(get_in_dir(coords, matrix, NorthEast))
    use #(_, t4) <- result.try(get_in_dir(coords, matrix, SouthEast))
    use #(_, t5) <- result.try(get_in_dir(coords, matrix, SouthWest))
    Ok(#(t1, [t2, t4], [t3, t5]))
  }

  case tiles {
    Ok(#(A, d1, d2)) -> {
      list.contains(d1, M)
      && list.contains(d1, S)
      && list.contains(d2, M)
      && list.contains(d2, S)
    }
    _ -> False
  }
}

// Auxiliaries Both Parts

fn get_in_dir(
  coords: #(Int, Int),
  matrix: Matrix(Token),
  dir: Dir,
) -> Result(#(#(Int, Int), Token), Nil) {
  let #(x, y) = coords

  case dir {
    North -> return_coords(matrix, x, y - 1)
    NorthEast -> return_coords(matrix, x + 1, y - 1)
    East -> return_coords(matrix, x + 1, y)
    SouthEast -> return_coords(matrix, x + 1, y + 1)
    South -> return_coords(matrix, x, y + 1)
    SouthWest -> return_coords(matrix, x - 1, y + 1)
    West -> return_coords(matrix, x - 1, y)
    NorthWest -> return_coords(matrix, x - 1, y - 1)
  }
}

fn return_coords(
  matrix: Matrix(a),
  x: Int,
  y: Int,
) -> Result(#(#(Int, Int), a), Nil) {
  use elem <- result.try(matrix.get(matrix, x, y))
  Ok(#(#(x, y), elem))
}
