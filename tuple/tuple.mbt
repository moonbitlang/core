/// Create a tuple with two elements.
/// 
/// # Example
/// ```
/// let tuple = pair(1, 2)
/// ```
pub fn pair[T, U](x : T, y : U) -> (T, U) {
  (x, y)
}

test "pair" {
  let tuple = pair(1, 2)
  @assertion.assert_eq(tuple, (1, 2))?
}

/// Get the first element of a tuple.
/// 
/// # Example
/// ```
/// let tuple = (1, 2)
/// let x = fst(tuple)
/// ```
pub fn fst[T, U](tuple : (T, U)) -> T {
  tuple.0
}

test "fst" {
  let tuple = (1, 2)
  @assertion.assert_eq(fst(tuple), 1)?
}

/// Get the second element of a tuple.
/// 
/// # Example
/// ```
/// let tuple = (1, 2)
/// let y = snd(tuple)
/// ```
pub fn snd[T, U](tuple : (T, U)) -> U {
  tuple.1
}

test "snd" {
  let tuple = (1, 2)
  @assertion.assert_eq(snd(tuple), 2)?
}

/// Map a function over the first element of a tuple.
/// 
/// # Example
/// ```
/// let tuple = (1, 2)
/// let mapped = map_fst(fn(x : Int) -> Int { x + 1 }, tuple)
/// ```
pub fn map_fst[T, U, V](f : (T) -> U, tuple : (T, V)) -> (U, V) {
  (f(tuple.0), tuple.1)
}

test "map_fst" {
  let tuple = (1, 2)
  let mapped = map_fst(fn(x : Int) -> Int { x + 1 }, tuple)
  @assertion.assert_eq(mapped, (2, 2))?
}

/// Map a function over the second element of a tuple.
/// 
/// # Example
/// ```
/// let tuple = (1, 2)
/// let mapped = map_snd(fn(x : Int) -> Int { x + 1 }, tuple)
/// ```
pub fn map_snd[T, U, V](f : (T) -> U, tuple : (V, T)) -> (V, U) {
  (tuple.0, f(tuple.1))
}

test "map_snd" {
  let tuple = (1, 2)
  let mapped = map_snd(fn(x : Int) -> Int { x + 1 }, tuple)
  @assertion.assert_eq(mapped, (1, 3))?
}

/// Map a function over both elements of a tuple.
/// 
/// # Example
/// ```
/// let tuple = (1, 2)
/// let mapped = map_both(fn(x : Int) -> Int { x + 1 }, fn(x : Int) -> Int { x - 1 }, tuple)
/// ```
pub fn map_both[T, U, V, W](
  f : (T) -> U,
  g : (V) -> W,
  tuple : (T, V)
) -> (U, W) {
  (f(tuple.0), g(tuple.1))
}

test "map_both" {
  let tuple = (1, 2)
  let mapped = map_both(
    fn(x : Int) -> Int { x + 1 },
    fn(x : Int) -> Int { x - 1 },
    tuple,
  )
  @assertion.assert_eq(mapped, (2, 1))?
}

/// Swap the elements of a tuple.
/// 
/// # Example
/// ```
/// let tuple = (1, 2)
/// let swapped = swap(tuple)
/// ```
pub fn swap[T, U](tuple : (T, U)) -> (U, T) {
  (tuple.1, tuple.0)
}

test "swap" {
  let tuple = (1, 2)
  let swapped = swap(tuple)
  let swapped_2 = swap(swapped)
  @assertion.assert_eq(swapped, (2, 1))?
  @assertion.assert_eq(swapped_2, tuple)?
}

/// Curry a function.
/// 
/// # Example
/// ```
/// let add = fn(x : Int, y : Int) -> Int { x + y }
/// let curried_add = curry(add)
/// curried_add(1)(2)
/// ```
pub fn curry[T, U, V](f : (T, U) -> V) -> (T) -> (U) -> V {
  fn(x : T) { fn(y : U) -> V { f(x, y) } }
}

test "curry" {
  let add = fn(x : Int, y : Int) -> Int { x + y }
  let curried_add = curry(add)
  @assertion.assert_eq(curried_add(1)(2), add(1, 2))?
}

/// Uncurry a function.
/// 
/// # Example
/// ```
/// let add = fn(x : Int) -> (Int) -> Int { fn(y : Int) -> Int { x + y } }
/// let uncurried_add = uncurry(add)
/// uncurried_add(1, 2)
/// ```
pub fn uncurry[T, U, V](f : (T) -> (U) -> V) -> (T, U) -> V {
  fn(x : T, y : U) { f(x)(y) }
}

test "uncurry" {
  let add = fn(x : Int) -> (Int) -> Int { fn(y : Int) -> Int { x + y } }
  let uncurried_add = uncurry(add)
  @assertion.assert_eq(uncurried_add(1, 2), add(1)(2))?
}

test "id_1" {
  let add = fn(x : Int, y : Int) -> Int { x + y }
  let curried_add = curry(add)
  let uncurried_add = uncurry(curried_add)
  @assertion.assert_eq(uncurried_add(1, 2), add(1, 2))?
}

test "id_2" {
  let add = fn(x : Int) -> (Int) -> Int { fn(y : Int) -> Int { x + y } }
  let uncurried_add = uncurry(add)
  let curried_add = curry(uncurried_add)
  @assertion.assert_eq(curried_add(1)(2), add(1)(2))?
}
