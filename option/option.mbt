/// Creates an `Option` containing a value if the given condition is true, otherwise returns `None`.
///
/// # Arguments
///
/// * `condition`: A boolean value indicating whether the option should contain a value.
/// * `value`: A function that returns the value to be contained in the option.
///
/// # Returns
///
/// An `Option` containing the value if the condition is true, otherwise `None`.
///
/// # Example
///
/// ```
/// let result = when(true, fn(){ "Hello, World!" })
/// debug(result) //output: Some("Hello, World!"
/// ```
pub fn when[T](condition : Bool, value : () -> T) -> Option[T] {
  if condition {
    Some(value())
  } else {
    None
  }
}

/// The `unless` function returns an `Option` value based on a condition.
///
/// `unless(condition, value)` is equivalent to `when(not(condition), value)`.
///
/// # Arguments
///
/// * `condition`: A boolean value indicating whether the condition is true or false.
/// * `value`: A function that returns a value of type `T`.
///
/// # Returns
///
/// An `Option` value that is `Some(value())` if the condition is false, otherwise `None`.
///
pub fn unless[T](condition : Bool, value : () -> T) -> Option[T] {
  when(condition.not(), value)
}


/// Creates an empty `Option` of type `T`.
pub fn empty[T]() -> Option[T] {
  None
}

/// Creates an `Option` that contains a value.
pub fn some[T](value : T) -> Option[T] {
  Some(value)
}

/// Maps the value of an `Option` using a provided function.
///
/// # Example
///
/// ```
/// let a = Some(5)
/// debug(a.map(fn(x){ x * 2 })) //output: Some(10)
///
/// let b = None
/// debug(b.map(fn(x){ x * 2 })) //output: None
/// ```
pub fn map[T, U](self : Option[T], f : (T) -> U) -> Option[U] {
  Some(f(self?))
}

/// Binds an option to a function that returns another option.
///
/// # Example
///
/// ```
/// let a = Option::Some(5)
/// let r1 = a.bind(fn(x){ Some(x * 2) })
/// debug(r1) //output: Some(10)
///
/// let b : Option[Int] = None
/// let r2 = b.bind(fn(x){ Some(x * 2) })
/// debug(r2) //output: None
/// ```
pub fn bind[T, U](self : Option[T], f : (T) -> Option[U]) -> Option[U] {
  f(self?)
}

test "bind" {
  let a = Option::Some(5)
  let b : Option[Int] = None
  @assertion.assert_eq(a.bind(fn(x){ Some(x * 2) }), Some(10))
  @assertion.assert_eq(b.bind(fn(x){ Some(x * 2) }), None)
}

/// Flattens an `Option` of `Option` into a single `Option`.
///
/// If the input `Option` is `Some(Some(value))`, the function returns `Some(value)`.
///
/// # Example
///
/// ```
/// let a = Some(Some(42));
/// debug(flatten(a)) //output: Some(42)
/// let b = Some(None)
/// debug(flatten(b)) //output: None
/// ```
pub fn flatten[T](self : Option[Option[T]]) -> Option[T] {
  self?
}

test "flatten" {
  let a : Option[Option[Int]] = Some(Some(42));
  @assertion.assert_eq(flatten(a),Some(42))
  let b : Option[Option[Int]] = Some(None)
  @assertion.assert_eq(flatten(b),None)
}

/// Checks if the option is empty.
pub fn is_empty[T](self : Option[T]) -> Bool {
  match self {
    None => true
    _ => false
  }
}

test "is_empty" {
  let x = Option::Some(3)
  let y: Option[Int] = None
  @assertion.assert_false(x.is_empty())
  @assertion.assert_true(y.is_empty())
}

/// Filters the option by applying the given predicate function `f`.
///
/// If the predicate function `f` returns `true` for the value contained in the option,
/// the same option is returned. Otherwise, `None` is returned.
///
/// # Example
/// ```
/// let x = Some(3)
/// debug(x.filter(fn(x){ x > 5 })) //output: None
/// debug(x.filter(fn(x){ x < 5 })) //output: Some(3)
/// ```
pub fn filter[T](self : Option[T], f : (T) -> Bool) -> Option[T] {
  if f(self?) {
    self
  } else {
    None
  }
}

test "filter" {
  let x = Option::Some(3)
  @assertion.assert_eq(x.filter(fn(x){ x > 5 }),None)
  @assertion.assert_eq(x.filter(fn(x){ x < 5 }),Some(3))
}

/// Return the contained `Some` value or the provided default.
pub fn or[T](self : Option[T], default : T) -> T {
  match self {
    None => default
    Some(t) => t
  }
}

test "or" {
  let x = Option::Some(3)
  @assertion.assert_eq(x.or(5), 3)
  @assertion.assert_eq((None : Option[Int]).or(5), 5)
}

/// Return the contained `Some` value or the provided default.
///
/// Default is lazily evaluated
pub fn or_else[T](self : Option[T], default : () -> T) -> T {
  match self {
    None => default()
    Some(t) => t
  }
}

test "or else" {
  let x = Option::Some(3)
  @assertion.assert_eq(x.or_else(fn () { 5 }), 3)
  @assertion.assert_eq((None : Option[Int]).or_else(fn () { 5 }), 5)
}