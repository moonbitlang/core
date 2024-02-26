/// Convert array to list.
/// 
/// # Example
///
/// ```
/// let ls = of_array([1, 2, 3, 4, 5])
/// println(ls) // output: of_array([1, 2, 3, 4, 5])
/// ```
pub fn of_array[T](arr : Array[T]) -> List[T] {
  let mut list = List::Nil
  for i = arr.length() - 1; i >= 0; i = i - 1 {
    list = List::Cons(arr[i], list)
  }
  return list
}

test "of_array" {
  let ls = of_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls, Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil))))))
}

/// Get the length of the list.
pub fn length[T](self : List[T]) -> Int {
  match self {
    Nil => 0
    Cons(_, tail) => 1 + length(tail)
  }
}

test "length" {
  let ls = of_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.length(), 5)
}

/// Iterates over the list.
/// 
/// # Example
/// 
/// ```
/// of_array([1, 2, 3, 4, 5]).iter(print) // output: 12345
/// ```
pub fn iter[T](self : List[T], f : (T) -> Unit) {
  match self {
    Nil => ()
    Cons(head, tail) => {
      f(head)
      iter(tail, f)
    }
  }
}

test "iter" {
  let ls = of_array([1, 2, 3, 4, 5])
  let mut i = 0
  ls.iter(fn(x) { @assertion.assert_eq(x, i + 1); i = i + 1 })
}

/// Iterates over the list with index.
/// 
/// # Example
/// 
/// ```
/// of_array([1, 2, 3, 4, 5]).iteri(fn(i, x) { print("(\(i),\(x)) ") }) 
/// // output: (0,1) (1,2) (2,3) (3,4) (4,5)
/// ```
pub fn iteri[T](self : List[T], f : (Int, T) -> Unit) {
  let mut i = 0
  self.iter(fn(x) { f(i, x); i = i + 1 })
}

test "iteri" {
  let mut v = 0
  let ls = of_array([1, 2, 3, 4, 5])
  ls.iteri(
    fn(i, x) {
      @assertion.assert_eq(x, v + 1)
      @assertion.assert_eq(i, v)
      v = v + 1
    },
  )
}

/// Maps the list.
/// 
/// # Example
/// 
/// ```
/// debug(of_array([1, 2, 3, 4, 5]).map(fn(x){ x * 2}))
/// // output: of_array([2, 4, 6, 8, 10])
/// ```
pub fn map[T, U](self : List[T], f : (T) -> U) -> List[U] {
  match self {
    Nil => Nil
    Cons(head, tail) => Cons(f(head), map(tail, f))
  }
}

test "map" {
  let ls = of_array([1, 2, 3, 4, 5])
  let rs = of_array([2, 4, 6, 8, 10])
  @assertion.assert_eq(ls.map(fn(x) { x * 2 }), rs)
}

/// Convert list to array.
pub fn to_array[T : Default](self : List[T]) -> Array[T] {
  let arr = Array::make(self.length(), T::default())
  self.iteri(fn(i, x) { arr[i] = x })
  return arr
}

/// Filter the list.
/// 
/// # Example
/// 
/// ```
/// debug(of_array([1, 2, 3, 4, 5]).filter(fn(x){ x % 2 == 0}))
/// // output: of_array([2, 4])
/// ```
pub fn filter[T](self : List[T], f : (T) -> Bool) -> List[T] {
  match self {
    Nil => Nil
    Cons(head, tail) =>
      if f(head) {
        Cons(head, filter(tail, f))
      } else {
        filter(tail, f)
      }
  }
}

test "filter" {
  let ls = of_array([1, 2, 3, 4, 5])
  let rs = of_array([2, 4])
  @assertion.assert_eq(ls.filter(fn(x) { x % 2 == 0 }), rs)
}

/// Tail of the list.
/// 
/// # Example
/// 
/// ```
/// debug(of_array([1, 2, 3, 4, 5]).tail())
/// // output: of_array([2, 3, 4, 5])
/// ```
pub fn tail[T](self : List[T]) -> List[T] {
  match self {
    Nil => Nil
    Cons(_, tail) => tail
  }
}

test "tail" {
  let ls = of_array([1, 2, 3, 4, 5])
  let rs = of_array([2, 3, 4, 5])
  @assertion.assert_eq(ls.tail(), rs)
}

/// Get first element of the list.
/// 
/// # Example
/// 
/// ```
/// debug(of_array([1, 2, 3, 4, 5]).head())
/// // output: 1
/// ```
pub fn head[T](self : List[T]) -> T {
  match self {
    Nil => abort("head of empty list")
    Cons(head, _) => head
  }
}

test "head" {
  let ls = of_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.head(), 1)
}

/// Get first element of the list.
/// 
/// # Example
/// 
/// ```
/// debug(of_array([1, 2, 3, 4, 5]).head())
/// // output: Some(1)
/// debug(of_array([]).head())
/// // output: None
/// ```
pub fn head_option[T](self : List[T]) -> Option[T] {
  match self {
    Nil => None
    Cons(head, _) => Some(head)
  }
}

test "head option" {
  let ls = of_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.head_option(), Some(1))
  let ls2 = of_array([])
  @assertion.assert_eq(ls2, Nil)
}

/// Last element of the list.
/// 
/// # Example
/// 
/// ```
/// debug(of_array([1, 2, 3, 4, 5]).last())
/// // output: 5
/// ```
pub fn last[T](self : List[T]) -> T {
  match self {
    Nil => abort("last of empty list")
    Cons(head, Nil) => head
    Cons(_, tail) => last(tail)
  }
}

test "last" {
  let ls = of_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.last(), 5)
}

/// Init of the list.
/// 
/// # Example
/// 
/// ```
/// debug(of_array([1, 2, 3, 4, 5]).init_())
/// // output: of_array([1, 2, 3, 4])
/// ```
pub fn init_[T](self : List[T]) -> List[T] {
  match self {
    Nil => Nil
    Cons(_, Nil) => Nil
    Cons(head, tail) => Cons(head, init_(tail))
  }
}

test "init_" {
  let ls = of_array([1, 2, 3, 4, 5])
  let rs = of_array([1, 2, 3, 4])
  @assertion.assert_eq(ls.init_(), rs)
}

/// Concatenate two lists.
///
/// # Example
///  
/// ```
/// let ls = of_array([1, 2, 3, 4, 5]).concat(of_array([6, 7, 8, 9, 10]))
/// debug(ls) // output: of_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
/// ```
pub fn concat[T](self : List[T], other : List[T]) -> List[T] {
  match self {
    Nil => other
    Cons(head, tail) => Cons(head, concat(tail, other))
  }
}

test "concat" {
  let ls = of_array([1, 2, 3, 4, 5])
  let rs = of_array([6, 7, 8, 9, 10])
  let ts = of_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  @assertion.assert_eq(ls.concat(rs), ts)
}

/// Reverse the list.
/// 
/// # Example
/// 
/// ```
/// debug(of_array([1, 2, 3, 4, 5]).reverse())
/// // output: of_array([5, 4, 3, 2, 1])
/// ```
pub fn reverse[T](self : List[T]) -> List[T] {
  match self {
    Nil => Nil
    Cons(head, tail) => concat(reverse(tail), Cons(head, Nil))
  }
}

test "reverse" {
  let ls = of_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls, ls.reverse().reverse())
}

/// Fold the list.
///
/// # Example
/// 
/// ```
/// let r = of_array([1, 2, 3, 4, 5]).fold(0, fn(acc, x) { acc + x })
/// debug(r) // output: 15
/// ```
pub fn fold[T, U](self : List[T], initial : U, f : (U, T) -> U) -> U {
  match self {
    Nil => initial
    Cons(head, tail) => fold(tail, f(initial, head), f)
  }
}

test "fold" {
  let ls = of_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.fold(0, fn(acc, x) { acc + x }), 15)
}

/// Zip two lists.
///
/// # Example
/// 
/// ```
/// let r = zip(of_array([1, 2, 3, 4, 5]), of_array([6, 7, 8, 9, 10]))
/// debug(r) // output: of_array([(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)]
/// ```
/// 
/// # Panics
///
/// If the two lists have different lengths, the function will panic.
///
pub fn zip[T, U](self : List[T], other : List[U]) -> List[(T, U)] {
  match (self, other) {
    (Nil, Nil) => Nil
    (Cons(x, xs), Cons(y, ys)) => Cons((x, y), zip(xs, ys))
    _ => abort("zip: lists have different lengths")
  }
}

/// map over the list and concat all results.
///
/// `concat_map(f, ls)` equal to `ls.map(f).fold(Nil, fn(acc, x) { acc.concat(x) })))`
///
/// # Example
/// 
/// ```
/// let ls = of_array([1, 2, 3])
/// let r = ls.concat_map(fn(x) { [x, x * 2] })
/// debug(r) // output: of_array([1, 2, 2, 4, 3, 6])
/// ```
pub fn concat_map[T, U](self : List[T], f : (T) -> List[U]) -> List[U] {
  match self {
    Nil => Nil
    Cons(head, tail) => concat(f(head), concat_map(tail, f))
  }
}

test "concat_map" {
  let ls = of_array([1, 2, 3])
  let rs = of_array([1, 2, 2, 4, 3, 6])
  @assertion.assert_eq(ls.concat_map(fn(x) { of_array([x, x * 2]) }), rs)
}

/// Get nth element of the list
pub fn nth[T](self : List[T], n : Int) -> T {
  match self {
    Nil => abort("nth: index out of bounds")
    Cons(head, tail) => if n == 0 { head } else { nth(tail, n - 1) }
  }
}

test "nth" {
  let ls = of_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.nth(0), 1)
  @assertion.assert_eq(ls.nth(1), 2)
  @assertion.assert_eq(ls.nth(2), 3)
  @assertion.assert_eq(ls.nth(3), 4)
  @assertion.assert_eq(ls.nth(4), 5)
}

/// Create a list of length n with the given value
///
/// # Example
/// 
/// ```
/// debug(repeat(5, 1)) // output: of_array([1, 1, 1, 1, 1])
/// ```
pub fn repeat[T](n : Int, x : T) -> List[T] {
  if n == 0 {
    Nil
  } else {
    Cons(x, repeat(n - 1, x))
  }
}

test "repeat" {
  let ls = of_array([1, 1, 1, 1, 1])
  @assertion.assert_eq(repeat(5, 1), ls)
}

/// Insert separator to the list.
/// 
/// # Example
/// 
/// ```
/// let ls = of_array(["1", "2", "3", "4", "5"]).separate_by("|")
/// debug(ls) // output: of_array(["1", "|", "2", "|", "3", "|", "4", "|", "5"])
/// ```
pub fn separate_by[T](self : List[T], seperator : T) -> List[T] {
  match self {
    Nil => Nil
    Cons(head, Nil) => Cons(head, Nil)
    Cons(head, tail) =>
      Cons(head, Cons(seperator, separate_by(tail, seperator)))
  }
}

test "separate_by" {
  let ls = of_array(["1", "|", "2", "|", "3", "|", "4", "|", "5"])
  @assertion.assert_eq(of_array(["1", "2", "3", "4", "5"]).separate_by("|"), ls)
}

/// Check if the list is empty.
pub fn is_empty[T](self : List[T]) -> Bool {
  match self {
    Nil => true
    _ => false
  }
}

test "is_empty" {
  let ls = of_array([1, 2, 3, 4, 5])
  @assertion.assert_false(ls.is_empty())
  @assertion.assert_true(List::Nil.is_empty())
}

/// Unzip two lists.
///
/// # Example
///
/// ```
/// let (a,b) = unzip(of_array([(1,2),(3,4),(5,6)]))
/// debug(a) // output: of_array([1, 3, 5])
/// debug(b) // output: of_array([2, 4, 6])
/// ```
pub fn unzip[T, U](list : List[(T, U)]) -> (List[T], List[U]) {
  match list {
    Nil => (Nil, Nil)
    Cons((x, y), xs) => {
      let (xs, ys) = unzip(xs)
      (Cons(x, xs), Cons(y, ys))
    }
  }
}

test "unzip" {
  let ls = of_array([(1, 2), (3, 4), (5, 6)])
  let (a, b) = unzip(ls)
  @assertion.assert_eq(a, of_array([1, 3, 5]))
  @assertion.assert_eq(b, of_array([2, 4, 6]))
}

/// flatten a list of lists.
/// 
/// # Example
/// 
/// ```
/// let ls = flatten(of_array([of_array([1,2,3]), of_array([4,5,6]), of_array([7,8,9])]))
/// debug(ls) // output: of_array([1, 2, 3, 4, 5, 6, 7, 8, 9])
/// ```
pub fn flatten[T](list : List[List[T]]) -> List[T] {
  match list {
    Nil => Nil
    Cons(head, tail) => concat(head, flatten(tail))
  }
}

test "flatten" {
  let ls = of_array(
    [of_array([1, 2, 3]), of_array([4, 5, 6]), of_array([7, 8, 9])],
  )
  let rs = of_array([1, 2, 3, 4, 5, 6, 7, 8, 9])
  @assertion.assert_eq(flatten(ls), rs)
}

pub fn debug_write[T : Debug](self : List[T], buf : Buffer) {
  fn aux(xs : List[T]) {
    match xs {
      Nil => ()
      Cons(x, Nil) => x.debug_write(buf)
      Cons(x, xs) => {
        x.debug_write(buf)
        buf.write_string(", ")
        aux(xs)
      }
    }
  }

  buf.write_string("of_array([")
  aux(self)
  buf.write_string("])")
}

pub fn to_string[T : Show](self : List[T]) -> String {
  fn aux(xs : List[T]) -> String {
    match xs {
      Nil => ""
      Cons(x, Nil) => x.to_string()
      Cons(x, xs) => x.to_string() + ", " + aux(xs)
    }
  }

  "of_array([" + aux(self) + "])"
}

/// Get maximum element of the list.
pub fn maximum[T : Compare](self : List[T]) -> T {
  match self {
    Nil => abort("maximum: empty list")
    Cons(x, Nil) => x
    Cons(x, xs) => {
      let y = maximum(xs)
      if x > y {
        x
      } else {
        y
      }
    }
  }
}

test "maximum" {
  let ls = of_array([1, 123, 52, 3, 6, 0, -6, -76])
  @assertion.assert_eq(ls.maximum(), 123)
}

/// Get minimum element of the list.
pub fn minimum[T : Compare](self : List[T]) -> T {
  match self {
    Nil => abort("minimum: empty list")
    Cons(x, Nil) => x
    Cons(x, xs) => {
      let y = minimum(xs)
      if x < y {
        x
      } else {
        y
      }
    }
  }
}

test "minimum" {
  let ls = of_array([1, 123, 52, 3, 6, 0, -6, -76])
  @assertion.assert_eq(ls.minimum(), -76)
}

/// Sort the list in ascending order.
///
/// # Example
/// 
/// ```
/// let ls = sort(of_array([1,123,52,3,6,0,-6,-76]))
/// debug(ls) // output: of_array([-76, -6, 0, 1, 3, 6, 52, 123])
/// ```
pub fn sort[T : Compare](self : List[T]) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => {
      let smaller = filter(xs, fn(y) { y < x })
      let greater = filter(xs, fn(y) { y >= x })
      concat(sort(smaller), Cons(x, sort(greater)))
    }
  }
}

test "sort" {
  let ls = of_array([1, 123, 52, 3, 6, 0, -6, -76])
  let rs = of_array([-76, -6, 0, 1, 3, 6, 52, 123])
  @assertion.assert_eq(ls.sort(), rs)
}

/// Concatenate two lists.
///
/// `a + b` equal to `a.concat(b)`
pub fn op_add[T](self : List[T], other : List[T]) -> List[T] {
  self.concat(other)
}

/// Check if the list contains the value.
pub fn contain[T : Eq](self : List[T], value : T) -> Bool {
  match self {
    Nil => false
    Cons(x, xs) => if x == value { true } else { contain(xs, value) }
  }
}

test "contain" {
  let ls = of_array([1, 2, 3])
  @assertion.assert_true(ls.contain(1))
  @assertion.assert_true(ls.contain(2))
  @assertion.assert_true(ls.contain(3))
  @assertion.assert_false(ls.contain(0))
  @assertion.assert_false(ls.contain(4))
}

/// Produces a collection iteratively.
///
/// # Example
///
/// ```
/// // of_array([0, 1, 2])
/// unfold(0, fn { i => if i == 3 { None } else { Some(i, i + 1) } }) |> debug 
/// ```
pub fn unfold[T, State](init : State, f : (State) -> Option[(T, State)]) ->
     List[T] {
  match f(init) {
    Some(element, new_state) => Cons(element, unfold(new_state, f))
    None => Nil
  }
}

test "unfold" {
  let ls = unfold(0, fn { i => if i == 3 { None } else { Some(i, i + 1) } })
  @assertion.assert_eq(ls, Cons(0, Cons(1, Cons(2, Nil))))
}
