import gleam/bool
import gleam/int
import gleam/list
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import glearray

// Little matrix library

pub opaque type Matrix(a) {
  Matrix(data: glearray.Array(a), width: Int, height: Int)
}

fn get(matrix: Matrix(a), x: Int, y: Int) -> Result(a, Nil) {
  let w = matrix.width
  let h = matrix.height

  use <- bool.guard({ x < 0 || y < 0 || x >= w || y >= h }, Error(Nil))
  let w = matrix.width
  glearray.get(matrix.data, y * w + x)
}

fn from_list_of_lists(lists: List(List(a))) -> Matrix(a) {
  let assert [l, ..] = lists
  let w = list.length(l)
  let h = list.length(lists)
  let data = lists |> list.flatten() |> glearray.from_list()
  Matrix(data: data, width: w, height: h)
}

fn iter_coords_matrix(matrix: Matrix(a)) -> yielder.Yielder(#(Int, Int)) {
  {
    let ver = yielder.range(0, matrix.height - 1)
    use y <- yielder.map(ver)

    let hor = yielder.range(0, matrix.width - 1)
    use x <- yielder.map(hor)

    #(x, y)
  }
  |> yielder.flatten()
}

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
  |> from_list_of_lists()
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
    use coord <- yielder.filter(iter_coords_matrix(matrix))
    let assert Ok(n) = get(matrix, coord.0, coord.1)
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
  case get(map, pos.0, pos.1) {
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
