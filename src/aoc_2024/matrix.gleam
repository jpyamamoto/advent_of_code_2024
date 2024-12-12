import gleam/bool
import gleam/list
import gleam/yielder
import glearray

// Little matrix library

pub type Matrix(a) {
  Matrix(data: glearray.Array(a), width: Int, height: Int)
}

pub fn get(matrix: Matrix(a), x: Int, y: Int) -> Result(a, Nil) {
  let w = matrix.width
  let h = matrix.height

  use <- bool.guard({ x < 0 || y < 0 || x >= w || y >= h }, Error(Nil))
  let w = matrix.width
  glearray.get(matrix.data, y * w + x)
}

pub fn in_bounds(matrix: Matrix(a), x: Int, y: Int) -> Bool {
  let w = matrix.width
  let h = matrix.height
  x < 0 || y < 0 || x >= w || y >= h
}

pub fn from_list_of_lists(lists: List(List(a))) -> Matrix(a) {
  let assert [l, ..] = lists
  let w = list.length(l)
  let h = list.length(lists)
  let data = lists |> list.flatten() |> glearray.from_list()
  Matrix(data: data, width: w, height: h)
}

pub fn iter_coords_matrix(matrix: Matrix(a)) -> yielder.Yielder(#(Int, Int)) {
  {
    let ver = yielder.range(0, matrix.height - 1)
    use y <- yielder.map(ver)

    let hor = yielder.range(0, matrix.width - 1)
    use x <- yielder.map(hor)

    #(x, y)
  }
  |> yielder.flatten()
}
