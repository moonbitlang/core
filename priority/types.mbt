///|
struct T[A] {
  node : Node[A]
  size : Int
}

///|
enum Node[A] {
  Empty
  Leaf(A)
  Branch(A, left~ : T[A], right~ : T[A])
}
