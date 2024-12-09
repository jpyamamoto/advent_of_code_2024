import gleam/bool
import gleam/deque.{type Deque}
import gleam/int
import gleam/list
import gleam/option.{type Option, Some}
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import gleam/yielder

type SpaceT {
  File(id: Int)
  Free
}

pub opaque type Block {
  Block(space: Int, kind: SpaceT)
}

pub fn parse(input: String) -> List(Block) {
  let space_types =
    yielder.iterate(0, int.add(_, 1))
    |> yielder.map(File)
    |> yielder.intersperse(Free)

  input
  |> string.split("")
  |> yielder.from_list()
  |> yielder.map(fn(d) {
    let assert Ok(n) = int.parse(d)
    n
  })
  |> yielder.map2(space_types, Block)
  |> yielder.to_list()
}

pub fn pt_1(input: List(Block)) {
  input
  |> deque.from_list()
  |> compress(deque.new())
  |> deque.to_list()
  |> checksum()
}

pub fn pt_2(input: List(Block)) {
  let files =
    list.filter(input, fn(block) {
      case block {
        Block(_, File(_)) -> True
        Block(_, Free) -> False
      }
    })

  input
  |> move(files)
  |> checksum()
}

// Part 1 Auxiliaries

fn compress(system: Deque(Block), acc: Deque(Block)) -> Deque(Block) {
  {
    use front <- result.try(deque.pop_front(system))

    case front {
      #(Block(space: n, kind: File(a)), system) ->
        compress(system, deque.push_back(acc, Block(space: n, kind: File(a))))
      #(Block(space: free_space, kind: Free), system) ->
        case find_last_file(system) {
          Some(#(Block(space: file_space, kind: File(a)), system)) -> {
            use <- bool.lazy_guard(free_space < file_space, fn() {
              let remaining_space = file_space - free_space
              let new_last = Block(space: remaining_space, kind: File(a))
              let new_curr = Block(space: free_space, kind: File(a))

              compress(
                deque.push_back(system, new_last),
                deque.push_back(acc, new_curr),
              )
            })

            let remaining_space = free_space - file_space
            use <- bool.lazy_guard(remaining_space == 0, fn() {
              compress(
                system,
                deque.push_back(acc, Block(space: file_space, kind: File(a))),
              )
            })

            let system =
              deque.push_front(
                system,
                Block(space: remaining_space, kind: Free),
              )
            compress(
              system,
              deque.push_back(acc, Block(space: file_space, kind: File(a))),
            )
          }
          _ -> compress(system, acc)
        }
    }
    |> Ok
  }
  |> result.unwrap(acc)
}

fn checksum(system: List(Block)) {
  system
  |> yielder.from_list()
  |> yielder.flat_map(fn(block) {
    let Block(space: n, kind: k) = block
    k |> yielder.repeat() |> yielder.take(n)
  })
  |> yielder.index()
  |> yielder.fold(0, fn(acc, spec) {
    let #(block, i) = spec
    case block {
      Free -> acc
      File(id: n) -> i * n + acc
    }
  })
}

fn find_last_file(system: Deque(Block)) -> Option(#(Block, Deque(Block))) {
  case deque.pop_back(system) {
    Error(_) -> option.None
    Ok(#(Block(space: _, kind: Free), new_q)) -> new_q |> find_last_file()
    Ok(#(Block(space: n, kind: File(a)), new_q)) ->
      Some(#(Block(space: n, kind: File(a)), new_q))
  }
}

// Part 2 Auxiliaries

fn move(system: List(Block), files: List(Block)) -> List(Block) {
  files
  |> list.reverse()
  |> list.fold(system, fn(system, block) { move_before(system, block) })
  |> clean()
}

fn move_before(system: List(Block), block: Block) -> List(Block) {
  let assert Block(space: space, kind: File(a)) = block

  case system {
    [] -> []
    [Block(space: free_space, kind: Free), ..rest] -> {
      use <- bool.lazy_guard(free_space >= space, fn() {
        let remaining = free_space - space
        use <- bool.guard(remaining == 0, [
          Block(space: space, kind: File(a)),
          ..rest
        ])
        [
          Block(space: space, kind: File(a)),
          Block(space: remaining, kind: Free),
          ..rest
        ]
      })
      [Block(space: free_space, kind: Free), ..move_before(rest, block)]
    }
    [Block(n, File(b)), ..rest] -> {
      use <- bool.guard(a == b, [Block(n, File(b)), ..rest])
      [Block(n, File(b)), ..move_before(rest, block)]
    }
  }
}

fn clean(system: List(Block)) -> List(Block) {
  system
  |> list.fold(#([], set.new()), fn(data, block) {
    let #(rest, visited) = data

    case block {
      Block(n, Free) -> #([Block(n, Free), ..rest], visited)
      Block(n, File(a)) -> {
        use <- bool.guard(set.contains(visited, a), #(
          [Block(n, Free), ..rest],
          visited,
        ))
        #([Block(n, File(a)), ..rest], set.insert(visited, a))
      }
    }
  })
  |> pair.first()
  |> list.reverse()
}
