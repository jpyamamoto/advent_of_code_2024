import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import gleam/string_tree
import gleam/yielder

// Constants

const width = 101

const height = 103

const seconds = 100

// Types

pub opaque type Robot {
  Robot(x: Int, y: Int, v_x: Int, v_y: Int)
}

// Parsing

pub fn parse(input: String) -> List(Robot) {
  let lines = string.split(input, "\n")

  use line <- list.map(lines)
  let assert Ok(#(pos, vel)) = string.split_once(line, " ")
  let pos = string.drop_start(pos, 2)
  let vel = string.drop_start(vel, 2)
  let assert Ok(#(pos_x, pos_y)) = string.split_once(pos, ",")
  let assert Ok(#(vel_x, vel_y)) = string.split_once(vel, ",")

  let assert Ok(x) = int.parse(pos_x)
  let assert Ok(y) = int.parse(pos_y)
  let assert Ok(v_x) = int.parse(vel_x)
  let assert Ok(v_y) = int.parse(vel_y)

  Robot(x, y, v_x, v_y)
}

// Solutions

pub fn pt_1(input: List(Robot)) {
  input
  |> list.map(move_robot(_, seconds))
  |> list.group(get_quadrant)
  |> dict.delete(5)
  |> dict.values()
  |> list.map(list.length)
  |> int.product()
}

pub fn pt_2(input: List(Robot)) {
  {
    use cycle <- yielder.find(yielder.range(0, 10_000))
    let curr_robots = list.map(input, move_robot(_, cycle))
    let image = image_robots(curr_robots)
    {
      use <- bool.guard(!string.contains(image, "■■■■■■■■■■■"), False)
      io.println(string.append("Cycle: ", int.to_string(cycle)))
      io.println(image)
      True
    }
  }
  |> result.unwrap(0)
}

// Auxiliaries

fn move_robot(robot: Robot, seconds: Int) -> #(Int, Int) {
  let d_x = robot.v_x * seconds
  let d_y = robot.v_y * seconds
  let abs_x = robot.x + d_x
  let abs_y = robot.y + d_y

  let assert Ok(n_x) = int.modulo(abs_x, width)
  let assert Ok(n_y) = int.modulo(abs_y, height)
  #(n_x, n_y)
}

fn get_quadrant(coord: #(Int, Int)) -> Int {
  let #(x, y) = coord
  let #(m_x, m_y) = #(width / 2, height / 2)
  case { x == m_x || y == m_y }, { x < m_x }, { y < m_y } {
    True, _, _ -> 5
    False, True, True -> 1
    False, False, True -> 2
    False, True, False -> 3
    False, False, False -> 4
  }
}

fn image_robots(robots: List(#(Int, Int))) -> String {
  let set_robots = robots |> set.from_list()
  {
    let ys = yielder.range(0, height - 1)
    use acc, y <- yielder.fold(ys, string_tree.new())

    let xs = yielder.range(0, width - 1)
    use line, x <- yielder.fold(xs, string_tree.append(acc, "\n"))
    use <- bool.guard(
      set.contains(set_robots, #(x, y)),
      string_tree.append(line, "■"),
    )
    string_tree.append(line, "·")
  }
  |> string_tree.to_string()
}
