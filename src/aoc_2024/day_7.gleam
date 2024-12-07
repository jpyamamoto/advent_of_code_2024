import gleam/int
import gleam/list
import gleam/string

pub type Puzzle =
  #(Int, List(Int))

type Op =
  fn(Int, Int) -> Int

pub fn parse(input: String) -> List(Puzzle) {
  input
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert Ok(#(res_s, nums_s)) = string.split_once(line, ": ")
    let assert Ok(res) = int.parse(res_s)
    let nums =
      nums_s
      |> string.split(" ")
      |> list.map(fn(n_s) {
        let assert Ok(n) = int.parse(n_s)
        n
      })
    #(res, nums)
  })
}

pub fn pt_1(input: List(Puzzle)) {
  solution(input, [int.add, int.multiply])
}

pub fn pt_2(input: List(Puzzle)) {
  solution(input, [int.add, int.multiply, concat_ints])
}

fn solution(input: List(Puzzle), ops: List(Op)) -> Int {
  input
  |> list.filter(fn(pair) {
    let assert #(expected, [n, ..nums]) = pair
    operate(nums, ops, expected, n)
  })
  |> list.map(fn(pair) { pair.0 })
  |> int.sum()
}

fn operate(input: List(Int), ops: List(Op), expected: Int, acc: Int) -> Bool {
  case input {
    [] -> expected == acc
    [n, ..rest] ->
      list.any(ops, fn(op) { operate(rest, ops, expected, op(acc, n)) })
  }
}

// It really is a shame that gleam does not have a logarithm operation
fn concat_ints(x: Int, y: Int) -> Int {
  let assert Ok(dig_x) = int.digits(x, 10)
  let assert Ok(dig_y) = int.digits(y, 10)
  let assert Ok(results) = int.undigits(list.append(dig_x, dig_y), 10)
  results
}
