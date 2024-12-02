import gleam/int
import gleam/list
import gleam/string
import gleam/yielder

type Level =
  Int

type Report =
  List(Level)

pub fn parse(input: String) -> List(Report) {
  input
  |> string.split("\n")
  |> list.map(fn(line) {
    string.split(line, " ")
    |> list.map(fn(level_str) {
      let assert Ok(level) = int.parse(level_str)
      level
    })
  })
}

pub fn pt_1(input: List(Report)) {
  list.count(input, is_safe)
}

pub fn pt_2(input: List(Report)) {
  list.count(input, is_almost_safe)
}

// Part 1 Auxiliaries

fn is_safe(report: Report) -> Bool {
  { is_increasing(report) || is_decreasing(report) } && is_in_bounds(report)
}

fn is_increasing(report: Report) -> Bool {
  case report {
    [first, second, ..rest] -> first < second && is_increasing([second, ..rest])
    _ -> True
  }
}

fn is_decreasing(report: Report) -> Bool {
  case report {
    [first, second, ..rest] -> first > second && is_decreasing([second, ..rest])
    _ -> True
  }
}

fn is_in_bounds(report: Report) {
  case report {
    [first, second, ..rest] ->
      int.absolute_value(first - second) <= 3 && is_in_bounds([second, ..rest])
    _ -> True
  }
}

// Part 2 Auxiliaries

fn is_almost_safe(report: Report) -> Bool {
  is_safe(report)
  || {
    let l = list.length(report)
    yielder.range(from: 0, to: l - 1)
    |> yielder.any(fn(i) {
      let drop_list = pop_index(report, i)
      is_safe(drop_list)
    })
  }
}

fn pop_index(list: List(a), index: Int) -> List(a) {
  let #(left, right) = list.split(list, index)
  let right_drop = list.drop(right, 1)
  list.append(left, right_drop)
}
