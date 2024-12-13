import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/yielder

// Types

type Coord {
  Coord(x: Int, y: Int)
}

pub opaque type System {
  System(a: Coord, b: Coord, target: Coord)
}

// Parsing

pub fn parse(input: String) -> List(System) {
  input
  |> string.split("\n")
  |> yielder.from_list()
  |> yielder.sized_chunk(into: 4)
  |> yielder.map(fn(system_lines) {
    let assert [line_a, line_b, line_prize, ..] = system_lines
    let button_a = parse_button(line_a)
    let button_b = parse_button(line_b)
    let target = parse_prize(line_prize)
    System(a: button_a, b: button_b, target: target)
  })
  |> yielder.to_list()
}

fn parse_button(line: String) -> Coord {
  let assert [_, p1, n2] = string.split(line, "+")
  let assert Ok(#(n1, _)) = string.split_once(p1, ",")
  let assert Ok(x) = int.parse(n1)
  let assert Ok(y) = int.parse(n2)
  Coord(x, y)
}

fn parse_prize(line: String) -> Coord {
  let assert [_, p1, n2] = string.split(line, "=")
  let assert Ok(#(n1, _)) = string.split_once(p1, ",")
  let assert Ok(x) = int.parse(n1)
  let assert Ok(y) = int.parse(n2)
  Coord(x, y)
}

// Solutions

pub fn pt_1(input: List(System)) {
  solve(input, 0)
}

pub fn pt_2(input: List(System)) {
  solve(input, 10_000_000_000_000)
}

// Auxiliaries

fn solve(input: List(System), offset: Int) -> Int {
  {
    use system <- list.map(input)
    {
      let offset_system =
        System(
          system.a,
          system.b,
          Coord(system.target.x + offset, system.target.y + offset),
        )
      use #(a, b) <- option.then(solve_system(offset_system))
      Some(a * 3 + b)
    }
    |> option.unwrap(0)
  }
  |> int.sum()
}

fn solve_system(system: System) -> Option(#(Int, Int)) {
  let a = system.a.x
  let b = system.b.x
  let c = system.a.y
  let d = system.b.y
  let e = system.target.x
  let f = system.target.y

  let det = a * d - b * c
  let x_num = d * e - b * f
  let y_num = a * f - c * e

  let assert Ok(div_x) = int.modulo(x_num, det)
  let assert Ok(div_y) = int.modulo(y_num, det)

  use <- bool.guard(div_x != 0 || div_y != 0, None)
  let assert Ok(x) = int.divide(x_num, det)
  let assert Ok(y) = int.divide(y_num, det)
  Some(#(x, y))
}
