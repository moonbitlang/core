pub struct Iterator[T] {
  next : () -> Option[T]
  size_hint : () -> (Int, Option[Int])
}

pub fn Iterator::from_array[T](array: Array[T]) -> Iterator[T] {
  let size = array.length()
  let mut i = 0
  {
    next: fn() {
      @option.when(
        i < size,
        fn() {
          let rv = array[i]
          i += 1
          rv
        }
      )
    },
    size_hint: fn() {
      let hint = size - i
      (hint, Some(hint))
    },
  }
}

pub fn fold[X, Y](self : Iterator[X], init : Y, f : (X, Y) -> Y) -> Y {
  loop init, (self.next)() {
    accum, Some(x) => continue f(x, accum), (self.next)()
    accum, None => accum
  }
}

pub fn sum[T: Default + @num.Num](self : Iterator[T]) -> T {
  self.fold(T::default(), fn { acc, x => acc + x })
}

test "sum" {
  @assertion.assert_eq(Iterator::[1, 2, 3].sum(), 6)?
}
