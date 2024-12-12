import aoc_2024/matrix.{type Matrix}
import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder

// Types

pub type Coord =
  #(Int, Int)

pub type Region =
  Set(Coord)

// Parsing

pub fn parse(input: String) -> List(Region) {
  let map: Matrix(String) =
    input
    |> string.split("\n")
    |> list.map(string.split(_, ""))
    |> matrix.from_list_of_lists()

  map_to_regions(map)
}

fn map_to_regions(map: Matrix(String)) -> List(Region) {
  do_clustering(map, set.new(), [])
}

fn do_clustering(
  map: Matrix(String),
  visited: Set(Coord),
  all_regions: List(Region),
) -> List(Region) {
  case find_not_visited(map, visited) {
    Some(coord) -> {
      let #(region, new_visited) =
        complete_region(
          coord,
          map,
          set.insert(visited, coord),
          set.insert(set.new(), coord),
        )
      do_clustering(map, new_visited, [region, ..all_regions])
    }
    None -> all_regions
  }
}

fn find_not_visited(map: Matrix(String), visited: Set(Coord)) -> Option(Coord) {
  let all_coords = {
    use y <- yielder.flat_map(yielder.range(0, map.height - 1))
    use x <- yielder.map(yielder.range(0, map.width - 1))
    #(x, y)
  }

  {
    use #(x, y) <- yielder.find(all_coords)
    use <- bool.guard(set.contains(visited, #(x, y)), False)
    use <- bool.guard(result.is_ok(matrix.get(map, x, y)), True)
    False
  }
  |> option.from_result()
}

fn complete_region(
  curr: Coord,
  map: Matrix(String),
  visited: Set(Coord),
  region: Region,
) -> #(Region, Set(Coord)) {
  let #(x, y) = curr
  let assert Ok(r_id) = matrix.get(map, x, y)
  let neighs = [#(x - 1, y), #(x + 1, y), #(x, y - 1), #(x, y + 1)]

  use #(region, visited), c <- list.fold(neighs, #(region, visited))
  use <- bool.guard(set.contains(visited, c), #(region, visited))
  case matrix.get(map, c.0, c.1) {
    Ok(val) -> {
      use <- bool.guard(val != r_id, #(region, visited))
      complete_region(c, map, set.insert(visited, c), set.insert(region, c))
    }
    Error(_) -> #(region, visited)
  }
}

// Solutions

pub fn pt_1(input: List(Region)) {
  solve(input, compute_perimeter)
}

pub fn pt_2(input: List(Region)) {
  solve(input, count_sides)
}

fn solve(input: List(Region), f_perim: fn(Region) -> Int) -> Int {
  {
    use region <- list.map(input)

    let area = set.size(region)
    let perimeter = f_perim(region)

    area * perimeter
  }
  |> int.sum()
}

// Auxiliaries Part 1

fn compute_perimeter(region: Region) -> Int {
  region
  |> set.to_list()
  |> list.map(count_non_adjacent(_, region))
  |> int.sum()
}

fn count_non_adjacent(coord: Coord, region: Region) -> Int {
  let #(x, y) = coord
  let neighs = [#(x - 1, y), #(x + 1, y), #(x, y - 1), #(x, y + 1)]

  use neigh <- list.count(neighs)
  !set.contains(region, neigh)
}

// Auxiliaries Part 2

fn count_sides(region: Region) -> Int {
  region
  |> set.to_list()
  |> yielder.from_list()
  |> yielder.map(count_corners(_, region))
  |> yielder.fold(0, int.add)
}

fn count_corners(coord: Coord, region: Region) -> Int {
  let #(x, y) = coord
  let in_region = set.contains(region, _)

  let north = in_region(#(x, y - 1))
  let south = in_region(#(x, y + 1))
  let west = in_region(#(x - 1, y))
  let east = in_region(#(x + 1, y))
  let northeast = in_region(#(x + 1, y - 1))
  let southeast = in_region(#(x + 1, y + 1))
  let northwest = in_region(#(x - 1, y - 1))
  let southwest = in_region(#(x - 1, y + 1))

  [
    is_outer_corner(east, south, southeast),
    is_outer_corner(west, south, southwest),
    is_outer_corner(west, north, northwest),
    is_outer_corner(east, north, northeast),
    is_inner_corner(west, north),
    is_inner_corner(east, north),
    is_inner_corner(east, south),
    is_inner_corner(west, south),
  ]
  |> list.count(fn(x) { x })
}

fn is_outer_corner(c1: Bool, c2: Bool, c3: Bool) -> Bool {
  c1 && c2 && !c3
}

fn is_inner_corner(c1: Bool, c2: Bool) -> Bool {
  !c1 && !c2
}
