import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/regexp.{Match, from_string, scan}

pub opaque type Token {
  Do
  Dont
  Val(Int)
}

pub fn parse(input: String) -> List(Token) {
  let assert Ok(re) =
    "mul\\((?<left>\\d{1,3}),(?<right>\\d{1,3})\\)|do\\(\\)|don\\'t\\(\\)"
    |> from_string()

  re
  |> scan(input)
  |> list.map(fn(m) {
    case m {
      Match(_, [Some(l), Some(r)]) -> {
        let assert Ok(num_l) = int.parse(l)
        let assert Ok(num_r) = int.parse(r)
        Val(num_l * num_r)
      }
      Match("do()", _) -> Do
      _ -> Dont
    }
  })
}

pub fn pt_1(input: List(Token)) {
  input
  |> list.filter_map(fn(token) {
    case token {
      Val(v) -> Ok(v)
      _ -> Error(Nil)
    }
  })
  |> int.sum()
}

pub fn pt_2(input: List(Token)) {
  input
  |> conditional_sum(True, 0)
}

fn conditional_sum(input: List(Token), flag: Bool, acc: Int) {
  case input, flag {
    [], _ -> acc
    [Do, ..rest], _ -> conditional_sum(rest, True, acc)
    [Dont, ..rest], _ -> conditional_sum(rest, False, acc)
    [Val(v), ..rest], True -> conditional_sum(rest, True, acc + v)
    [Val(_), ..rest], False -> conditional_sum(rest, False, acc)
  }
}
