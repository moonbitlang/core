priv enum Node[A] {
  Nil
  Cons(content~ : A, left~ : Node[A], right~ : Node[A])
}

struct T[A] {
  mut root : Node[A]
  mut size : Int
}
