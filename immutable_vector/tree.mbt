let num_bits = 5

let branching_factor : Int = (1).lsl(num_bits)

let bitmask : Int = branching_factor - 1

pub fn Tree::empty[T]() -> Tree[T] {
  Tree::Empty
}

fn get_first[T](self : Tree[T]) -> T {
  match self {
    Leaf(leaf) => leaf[0]
    Node(node) => get_first(node[0])
    Empty => abort("Index out of bounds")
  }
}

fn get_last[T](self : Tree[T]) -> T {
  match self {
    Leaf(leaf) => leaf[leaf.length() - 1]
    Node(node) => get_last(node[node.length() - 1])
    Empty => abort("Index out of bounds")
  }
}

fn get[T](self : Tree[T], index : Int, shift : Int) -> T {
  match self {
    Tree::Leaf(leaf) => leaf[index.land(bitmask)]
    Node(node) =>
      get(node[index.lsr(shift).land(bitmask)], index, shift - num_bits)
    Empty => abort("Index out of bounds")
  }
}
