import gleam/int
import gleam/list
import gleam/order.{Eq, Gt, Lt}
import gleam/set.{type Set}
import gleam/string

type Rule =
  #(Int, Int)

type Update =
  List(Int)

pub fn parse(input: String) -> #(Set(Rule), List(Update)) {
  let assert Ok(#(rules, updates)) = string.split_once(input, "\n\n")
  #(parse_rules(rules), parse_updates(updates))
}

pub fn pt_1(input: #(Set(Rule), List(Update))) {
  input.1
  |> list.filter(fn(update) { sort_update(update, input.0) == update })
  |> list.map(get_middle_page)
  |> int.sum()
}

pub fn pt_2(input: #(Set(Rule), List(Update))) {
  input.1
  |> list.filter_map(fn(update) {
    let sorted = sort_update(update, input.0)
    case sorted == update {
      True -> Error(Nil)
      False -> Ok(sorted)
    }
  })
  |> list.map(get_middle_page)
  |> int.sum()
}

// Auxiliaries

fn sort_update(update: Update, rules_s: Set(Rule)) -> List(Int) {
  list.sort(update, fn(left, right) {
    case left == right, set.contains(rules_s, #(left, right)) {
      True, _ -> Eq
      _, True -> Lt
      _, _ -> Gt
    }
  })
}

fn get_middle_page(update: Update) -> Int {
  let l = list.length(update)
  let middle = l / 2

  let assert Ok(result) =
    update
    |> list.drop(middle)
    |> list.first()

  result
}

// Parsing Auxiliaries

fn parse_rules(input: String) -> Set(Rule) {
  input
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert Ok(#(before, after)) = string.split_once(line, "|")
    let assert Ok(num_before) = int.parse(before)
    let assert Ok(num_after) = int.parse(after)
    #(num_before, num_after)
  })
  |> set.from_list()
}

fn parse_updates(input: String) -> List(Update) {
  input
  |> string.split("\n")
  |> list.map(fn(line) {
    line
    |> string.split(",")
    |> list.map(fn(num_s) {
      let assert Ok(num) = int.parse(num_s)
      num
    })
  })
}
