pub fn when[T](condition : Bool, value : () -> T) -> Option[T] {
  if condition {
    Some(value())
  } else {
    None
  }
}

pub fn unless[T](condition : Bool, value : () -> T) -> Option[T] {
  Option::when(condition.not(), value)
}

pub fn empty[T]() -> Option[T] {
  None
}

pub fn some[T](value : T) -> Option[T] {
  Some(value)
}

pub fn map[T, U](self : Option[T], f : (T) -> U) -> Option[U] {
  Some(f(self?))
}

pub fn bind[T, U](self : Option[T], f : (T) -> Option[U]) -> Option[U] {
  f(self?)
}

pub fn flatten[T](self : Option[Option[T]]) -> Option[T] {
  self?
}

pub fn is_empty[T](self : Option[T]) -> Bool {
  match self {
    Nil => true
    _ => false
  }
}

pub fn filter[T](self : Option[T], f : (T) -> Bool) -> Option[T] {
  if f(self?) {
    self
  } else {
    None
  }
}
