pub fn pair[T, U](x : T, y : U) -> (T, U) {
  (x, y)
}

test "pair" {
  let tulpe = pair(1, 2)
  @assertion.assert_eq(tulpe, (1, 2))?
}

pub fn fst[T, U](tulpe : (T, U)) -> T {
  tulpe.0
}

test "fst" {
  let tulpe = (1, 2)
  @assertion.assert_eq(fst(tulpe), 1)?
}

pub fn snd[T, U](tulpe : (T, U)) -> U {
  tulpe.1
}

test "snd" {
  let tulpe = (1, 2)
  @assertion.assert_eq(snd(tulpe), 2)?
}

pub fn map_fst[T, U, V](f : (T) -> U, tulpe : (T, V)) -> (U, V) {
  (f(tulpe.0), tulpe.1)
}

test "map_fst" {
  let tulpe = (1, 2)
  let mapped = map_fst(fn(x : Int) -> Int { x + 1 }, tulpe)
  @assertion.assert_eq(mapped, (2, 2))?
}

pub fn map_snd[T, U, V](f : (T) -> U, tulpe : (V, T)) -> (V, U) {
  (tulpe.0, f(tulpe.1))
}

test "map_snd" {
  let tulpe = (1, 2)
  let mapped = map_snd(fn(x : Int) -> Int { x + 1 }, tulpe)
  @assertion.assert_eq(mapped, (1, 3))?
}

pub fn map_both[T, U, V, W](
  f : (T) -> U,
  g : (V) -> W,
  tulpe : (T, V)
) -> (U, W) {
  (f(tulpe.0), g(tulpe.1))
}

test "map_both" {
  let tulpe = (1, 2)
  let mapped = map_both(
    fn(x : Int) -> Int { x + 1 },
    fn(x : Int) -> Int { x - 1 },
    tulpe
  )
  @assertion.assert_eq(mapped, (2, 1))?
}

pub fn swap[T, U](tulpe : (T, U)) -> (U, T) {
  (tulpe.1, tulpe.0)
}

test "swap" {
  let tulpe = (1, 2)
  let swapped = swap(tulpe)
  let swapped_2 = swap(swapped)
  @assertion.assert_eq(swapped, (2, 1))?
  @assertion.assert_eq(swapped_2, tulpe)?
}

pub fn curry[T, U, V](f : (T, U) -> V) -> (T) -> (U) -> V {
  fn(x : T) { fn(y : U) -> V { f(x, y) } }
}

test "curry" {
  let add = fn(x : Int, y : Int) -> Int { x + y }
  let curried_add = curry(add)
  @assertion.assert_eq(curried_add(1)(2), add(1, 2))?
}

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
