import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/yielder

// Parse

pub fn parse(input: String) -> Dict(Int, Int) {
  let nums_s = string.split(input, " ")
  use acc, num_s <- list.fold(nums_s, dict.new())

  let assert Ok(num) = int.parse(num_s)
  dict.insert(acc, num, 1)
}

// Solutions

pub fn pt_1(input: Dict(Int, Int)) {
  solve(input, 25)
}

pub fn pt_2(input: Dict(Int, Int)) {
  solve(input, 75)
}

// Auxiliaries

fn solve(input: Dict(Int, Int), times: Int) -> Int {
  let final_state = {
    use acc, _ <- yielder.fold(yielder.range(1, times), input)
    blink_once(acc)
  }

  final_state
  |> dict.values()
  |> int.sum()
}

fn blink_once(rocks: Dict(Int, Int)) -> Dict(Int, Int) {
  use acc, rock, times <- dict.fold(rocks, dict.new())
  use new_rocks, rock <- list.fold(blink_for_rock(rock), acc)
  use prev <- dict.upsert(new_rocks, rock)
  case prev {
    None -> times
    Some(p) -> times + p
  }
}

fn blink_for_rock(rock: Int) -> List(Int) {
  case rock {
    0 -> [1]
    n -> {
      let assert Ok(ds) = int.digits(n, 10)
      let l = list.length(ds)
      use <- bool.lazy_guard(l % 2 != 0, fn() { [n * 2024] })
      let #(left, right) = list.split(ds, l / 2)
      let assert Ok(num_left) = int.undigits(left, 10)
      let assert Ok(num_right) = int.undigits(right, 10)
      [num_left, num_right]
    }
  }
}
