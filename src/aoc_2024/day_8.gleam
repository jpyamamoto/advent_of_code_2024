import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string
import gleam/yielder

// Types

type Coord =
  #(Int, Int)

type Antenas =
  Dict(String, List(Coord))

// Parsing

pub fn parse(input: String) -> #(Coord, Antenas) {
  let lines = string.split(input, "\n")

  let height = list.length(lines)
  let width = list.first(lines) |> result.unwrap("") |> string.length()

  let antenas =
    lines
    |> yielder.from_list()
    |> yielder.index()
    |> yielder.fold(dict.new(), fn(acc, pair) {
      let #(line, y) = pair

      line
      |> string.split("")
      |> yielder.from_list()
      |> yielder.index()
      |> yielder.fold(acc, fn(acc, pair) {
        let #(char, x) = pair
        case char {
          "." -> acc
          _ -> {
            dict.upsert(acc, char, fn(val) {
              case val {
                None -> [#(x, y)]
                Some(antenas) -> [#(x, y), ..antenas]
              }
            })
          }
        }
      })
    })

  #(#(width, height), antenas)
}

// Solutions

pub fn pt_1(input: #(Coord, Antenas)) {
  let #(dims, antenas) = input

  antenas
  |> dict.to_list()
  |> list.flat_map(fn(pair) { find_antinodes(pair.1, dims) })
  |> set.from_list()
  |> set.size()
}

pub fn pt_2(input: #(Coord, Antenas)) {
  let #(dims, antenas) = input

  antenas
  |> dict.to_list()
  |> list.filter(fn(pair) { list.length(pair.1) > 0 })
  |> list.flat_map(fn(pair) { find_loop_antinodes(pair.1, dims) })
  |> set.from_list()
  |> set.size()
}

// Auxiliaries

fn find_antinodes(nodes: List(Coord), dims: Coord) -> List(Coord) {
  case nodes {
    [] -> []
    [node_a, ..rest] -> {
      let some_antinodes =
        rest
        |> list.flat_map(fn(node_b) {
          let dist = distance(node_a, node_b)
          [
            #(node_b.0 + dist.0, node_b.1 + dist.1),
            #(node_a.0 - dist.0, node_a.1 - dist.1),
          ]
        })
        |> list.filter(fn(coord) { in_bounds(coord, dims) })

      list.append(some_antinodes, find_antinodes(rest, dims))
    }
  }
}

fn distance(a: Coord, b: Coord) -> Coord {
  #(b.0 - a.0, b.1 - a.1)
}

fn in_bounds(coord: Coord, dims: Coord) -> Bool {
  let #(c_x, c_y) = coord
  let #(width, height) = dims

  c_x >= 0 && c_y >= 0 && c_x < width && c_y < height
}

fn find_loop_antinodes(nodes: List(Coord), dims: Coord) -> List(Coord) {
  case nodes {
    [] -> []
    [node_a, ..rest] -> {
      let some_antinodes =
        rest
        |> list.flat_map(fn(node_b) {
          let diff = distance(node_a, node_b)
          let dir_1 = generate_antinodes_in_bounds(node_a, diff, dims)
          let dir_2 =
            generate_antinodes_in_bounds(node_a, #(-diff.0, -diff.1), dims)

          list.append([node_a, ..dir_1], dir_2)
        })
        |> list.filter(fn(coord) { in_bounds(coord, dims) })

      list.append(some_antinodes, find_loop_antinodes(rest, dims))
    }
  }
}

fn generate_antinodes_in_bounds(
  a: Coord,
  diff: Coord,
  dims: Coord,
) -> List(Coord) {
  let b = #(a.0 + diff.0, a.1 + diff.1)

  case in_bounds(b, dims) {
    True -> [b, ..generate_antinodes_in_bounds(b, diff, dims)]
    False -> []
  }
}
