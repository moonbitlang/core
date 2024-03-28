pub fn List::default[X]() -> List[X] {
  Nil
}

pub fn List::op_equal[X : Eq](xs : List[X], ys : List[X]) -> Bool {
  match (xs, ys) {
    (Nil, Nil) => true
    (Cons(h1, t1), Cons(h2, t2)) => h1 == h2 && t1 == t2
    (Nil, Cons(_, _)) | (Cons(_, _), Nil) => false
  }
}

pub fn debug_write[X : Debug](self : List[X], buf : Buffer) -> Unit {
  buf.write_string("List::[")
  loop self {
    Nil => buf.write_string("]")
    Cons(x, Nil) => {
      x.debug_write(buf)
      continue Nil
    }
    Cons(x, xs) => {
      x.debug_write(buf)
      buf.write_string(", ")
      continue xs
    }
  }
}

pub fn to_string[X : Debug](self : List[X]) -> String {
  let buf = Buffer::make(10)
  self.debug_write(buf)
  buf.to_string()
}
