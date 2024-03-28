pub fn op_equal[T : Eq, E : Eq](
  self : Result[T, E],
  other : Result[T, E]
) -> Bool {
  match (self, other) {
    (Ok(x), Ok(y)) => x == y
    (Err(x), Err(y)) => x == y
    _ => false
  }
}

pub fn compare[T : Compare, E : Compare](
  self : Result[T, E],
  other : Result[T, E]
) -> Int {
  match (self, other) {
    (Ok(x), Ok(y)) => x.compare(y)
    (Ok(_), Err(_)) => -1
    (Err(_), Ok(_)) => 1
    (Err(x), Err(y)) => x.compare(y)
  }
}

pub fn unwrap[T, E](self : Result[T, E]) -> T {
  match self {
    Ok(x) => x
    Err(_) => abort("called `Result::unwrap()` on an `Err` value")
  }
}
