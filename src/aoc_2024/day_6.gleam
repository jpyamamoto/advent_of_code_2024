import gleam/list
import gleam/set.{type Set}
import gleam/string
import gleam/yielder

// Types

pub opaque type Map {
  Map(data: Set(#(Int, Int)), width: Int, height: Int)
}

pub opaque type Token {
  Void
  Obstacle
}

pub opaque type Dir {
  North
  East
  South
  West
}

pub type Guard =
  #(Int, Int, Dir)

pub fn parse(input: String) -> #(Guard, Map) {
  let lines_chars =
    input
    |> string.split("\n")
    |> list.map(fn(l) { string.split(l, "") })

  let guard = find_guard(lines_chars)

  let matrix =
    lines_chars
    |> list.map(fn(line) {
      line
      |> list.map(fn(c) {
        case c {
          "#" -> Obstacle
          _ -> Void
        }
      })
    })
    |> from_list_of_lists()
  #(guard, matrix)
}

pub fn pt_1(input: #(Guard, Map)) {
  let #(guard, matrix) = input
  let visited = set.new() |> set.insert(#(guard.0, guard.1))

  guard
  |> do_patrol(matrix, visited)
  |> set.size()
}

pub fn pt_2(input: #(Guard, Map)) {
  let #(guard, map) = input
  let visited = set.new() |> set.insert(#(guard.0, guard.1))

  let patrol =
    guard |> do_patrol(map, visited) |> set.delete(#(guard.0, guard.1))

  patrol
  |> set.to_list()
  |> list.filter(fn(obs_pos) {
    let new_map = add_obstacle(map, obs_pos.0, obs_pos.1)
    has_loop(guard, new_map, set.new())
  })
  |> list.length()
}

// Parsing auxiliaries

fn find_guard(lines: List(List(String))) -> Guard {
  let assert Ok(#(x, y, dir)) =
    lines
    |> yielder.from_list()
    |> yielder.map(fn(line) {
      line
      |> yielder.from_list()
      |> yielder.index()
      |> yielder.find_map(fn(pair) {
        case pair.0 {
          "#" -> Error(Nil)
          "." -> Error(Nil)
          _ -> Ok(pair)
        }
      })
    })
    |> yielder.index()
    |> yielder.find_map(fn(pair) {
      let #(in_x, y) = pair
      case in_x {
        Error(_) -> Error(Nil)
        Ok(#(char, x)) -> {
          let dir = case char {
            "^" -> North
            ">" -> East
            "v" -> South
            _ -> West
          }
          Ok(#(x, y, dir))
        }
      }
    })

  #(x, y, dir)
}

// Part 1 Auxiliary

fn do_patrol(
  guard: Guard,
  map: Map,
  visited: Set(#(Int, Int)),
) -> Set(#(Int, Int)) {
  let new_pos = case in_bounds(guard, map) {
    True -> Ok(move_guard(guard, map))
    False -> Error(Nil)
  }

  let new_visited = set.insert(visited, #(guard.0, guard.1))

  case new_pos {
    Ok(new_guard) -> do_patrol(new_guard, map, new_visited)
    Error(_) -> visited
  }
}

// Part 2 Auxiliary

fn has_loop(guard: Guard, map: Map, visited: Set(Guard)) -> Bool {
  case set.contains(visited, guard), in_bounds(guard, map) {
    True, _ -> True
    False, False -> False
    False, True -> {
      let new_visited = set.insert(visited, guard)
      let new_guard = move_guard(guard, map)
      has_loop(new_guard, map, new_visited)
    }
  }
}

// Little Map Library

fn has_obstacle(map: Map, x: Int, y: Int) -> Bool {
  set.contains(map.data, #(x, y))
}

fn add_obstacle(map: Map, x: Int, y: Int) -> Map {
  let new_data = set.insert(map.data, #(x, y))
  Map(new_data, map.width, map.height)
}

fn from_list_of_lists(lists: List(List(Token))) -> Map {
  let assert [l, ..] = lists
  let w = list.length(l)
  let h = list.length(lists)

  let data =
    lists
    |> yielder.from_list()
    |> yielder.index()
    |> yielder.map(fn(line) {
      let #(line, y) = line

      line
      |> yielder.from_list()
      |> yielder.index()
      |> yielder.map(fn(pair) {
        let #(token, x) = pair
        #(x, y, token)
      })
    })
    |> yielder.flatten()
    |> yielder.filter(fn(pair) { pair.2 == Obstacle })
    |> yielder.fold(set.new(), fn(acc, elem) {
      let #(x, y, _) = elem
      set.insert(acc, #(x, y))
    })

  Map(data, w, h)
}

// Auxiliaries

fn in_bounds(guard: Guard, map: Map) -> Bool {
  let #(x, y, _) = guard
  let w = map.width
  let h = map.height

  x >= 0 && y >= 0 && x < w && y < h
}

fn move_guard(guard: Guard, map: Map) -> Guard {
  let #(x, y, dir) = guard

  let new_coords = move_in_dir(#(x, y), dir)
  let #(f_x, f_y) = move_in_dir(new_coords, dir)
  let obstacle_in_front = has_obstacle(map, f_x, f_y)

  let new_dir = case obstacle_in_front {
    True -> rotate_dir(dir)
    False -> dir
  }

  #(new_coords.0, new_coords.1, new_dir)
}

fn move_in_dir(coords: #(Int, Int), dir: Dir) -> #(Int, Int) {
  let #(x, y) = coords

  case dir {
    North -> #(x, y - 1)
    East -> #(x + 1, y)
    South -> #(x, y + 1)
    West -> #(x - 1, y)
  }
}

fn rotate_dir(dir: Dir) -> Dir {
  case dir {
    North -> East
    East -> South
    South -> West
    West -> North
  }
}
