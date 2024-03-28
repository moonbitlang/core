pub fn Option::default[X]() -> Option[X] {
  None
}

pub fn op_equal[X : Eq](self : Option[X], other : Option[X]) -> Bool {
  match (self, other) {
    (None, None) => true
    (Some(x), Some(y)) => x == y
    _ => false
  }
}

pub fn compare[X : Compare](self : Option[X], other : Option[X]) -> Int {
  match self {
    None =>
      match other {
        None => 0
        Some(_) => -1
      }
    Some(x) =>
      match other {
        None => 1
        Some(y) => x.compare(y)
      }
  }
}

pub fn unwrap[X](self : Option[X]) -> X {
  match self {
    None => abort("called `Option::unwrap()` on a `None` value")
    Some(x) => x
  }
}

pub fn to_string[X : Show](self : Option[X]) -> String {
  match self {
    None => "None"
    Some(x) => "Some(" + x.to_string() + ")"
  }
}
