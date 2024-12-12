import aoc_2024/matrix.{type Matrix}
import gleam/int
import gleam/list
import gleam/set.{type Set}
import gleam/string
import gleam/yielder

// Parsing

pub fn parse(input: String) -> Matrix(Int) {
  let lines = string.split(input, "\n")

  {
    use line <- list.map(lines)
    let chars = string.split(line, "")
    use char <- list.map(chars)
    let assert Ok(n) = int.parse(char)
    n
  }
  |> matrix.from_list_of_lists()
}

// Solutions

pub fn pt_1(input: Matrix(Int)) {
  let solution = solve(input)

  {
    use trails <- yielder.map(solution)
    {
      use trail <- set.map(trails)
      let assert Ok(l) = list.first(trail)
      l
    }
    |> set.size()
  }
  |> yielder.fold(0, int.add)
}

pub fn pt_2(input: Matrix(Int)) {
  input
  |> solve()
  |> yielder.map(set.size)
  |> yielder.fold(0, int.add)
}

// Auxiliaries

fn solve(matrix: Matrix(Int)) -> yielder.Yielder(Set(List(#(Int, Int)))) {
  let starting_points = {
    use coord <- yielder.filter(matrix.iter_coords_matrix(matrix))
    let assert Ok(n) = matrix.get(matrix, coord.0, coord.1)
    n == 0
  }

  use start <- yielder.map(starting_points)
  hike(start, -1, [], matrix, set.new())
}

fn hike(
  pos: #(Int, Int),
  prev: Int,
  trail: List(#(Int, Int)),
  map: Matrix(Int),
  dests: Set(List(#(Int, Int))),
) -> Set(List(#(Int, Int))) {
  let new_trail = [pos, ..trail]
  case matrix.get(map, pos.0, pos.1) {
    Ok(9) if prev == 8 -> set.insert(dests, new_trail)
    Ok(n) if n == prev + 1 -> {
      [
        #(pos.0 - 1, pos.1),
        #(pos.0 + 1, pos.1),
        #(pos.0, pos.1 - 1),
        #(pos.0, pos.1 + 1),
      ]
      |> list.map({ hike(_, n, new_trail, map, dests) })
      |> list.fold(set.new(), set.union)
    }
    _ -> dests
  }
}
