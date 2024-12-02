import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string

pub fn pt_1(input: String) {
  input
  |> parse()
  |> sort_lists()
  |> compute_diffs()
  |> list.reduce(fn(acc, n) { acc + n })
}

pub fn pt_2(input: String) {
  let #(keys, values) = parse(input)
  let frequencies = compute_freqs(values)

  compute_similarities(keys, frequencies)
  |> list.reduce(fn(acc, n) { acc + n })
}

// Part 1 Auxiliaries

fn parse(input: String) {
  input
  |> string.split(on: "\n")
  |> list.map(fn(l) {
    let assert [n1, n2] = string.split(l, on: "   ")
    let assert Ok(i1) = int.parse(n1)
    let assert Ok(i2) = int.parse(n2)
    #(i1, i2)
  })
  |> list.unzip()
}

fn sort_lists(input: #(List(Int), List(Int))) -> #(List(Int), List(Int)) {
  let #(l1, l2) = input
  let sl1 = list.sort(l1, by: int.compare)
  let sl2 = list.sort(l2, by: int.compare)
  #(sl1, sl2)
}

fn compute_diffs(input: #(List(Int), List(Int))) -> List(Int) {
  let #(l1, l2) = input

  list.zip(l1, l2)
  |> list.map(fn(pair) {
    let #(n1, n2) = pair
    int.absolute_value(n1 - n2)
  })
}

// Part 2 Auxiliaries

fn compute_freqs(input: List(Int)) -> Dict(Int, Int) {
  list.fold(input, dict.new(), fn(d, n) {
    dict.upsert(d, n, fn(v) {
      case v {
        Some(i) -> i + 1
        None -> 1
      }
    })
  })
}

fn compute_similarities(keys: List(Int), freqs: Dict(Int, Int)) -> List(Int) {
  list.map(keys, fn(i) {
    case dict.get(freqs, i) {
      Ok(v) -> i * v
      Error(Nil) -> 0
    }
  })
}
