///|
priv type InorderIterator[K, V] Array[T[K, V]]

///|
fn InorderIterator::new[K, V](root : T[K, V]) -> InorderIterator[K, V] {
  InorderIterator([])..move_left(root)
}

///|
fn InorderIterator::move_left[K, V](
  self : InorderIterator[K, V],
  node : T[K, V]
) -> Unit {
  loop node {
    Empty => ()
    Tree(_, left, _, ..) as curr => {
      self._.push(curr)
      continue left
    }
  }
}

///|
fn InorderIterator::next[K, V](self : InorderIterator[K, V]) -> (K, V)? {
  guard let Some(curr) = self._.pop() else { _ => return None }
  guard let Tree(key, _, right, value~, ..) = curr
  self.move_left(right)
  Some((key, value))
}

test "InorderIterator" {
  let arr = [(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7)]
  let set = from_array(arr)
  let iter = InorderIterator::new(set)
  for i = 0; ; i = i + 1 {
    match iter.next() {
      None => break
      Some(value) => assert_eq!(value, arr[i])
    }
  }
}
