
/// Iterates over each element.
///
/// # Arguments
///
/// - `self`: The array to iterate over.
/// - `f`: The function to apply to each element.
///
/// # Example
///
/// ```
/// [1, 2, 3, 4, 5].iter(fn(x){ print("\(x) ") }) //output: 1 2 3 4 5
/// ```
pub fn iter[T](self : Array[T], f : (T) -> Unit) {
  let mut i = 0
  while i < self.length() {
    f(self[i])
    i = i + 1
  }
}

test "iteri" {
  let mut i = 0
  [1, 2, 3, 4, 5].iter(fn(elem){
    @assertion.assert_eq(elem,i+1)
    i = i + 1
  })
}

/// Iterates over the array with index. 
///
/// # Arguments
///
/// - `self`: The array to iterate over.
/// - `f`: A function that takes an `Int` representing the index and a `T` representing the element of the array, and returns `Unit`.
///
/// # Example
///
/// ```
/// [1, 2, 3, 4, 5].iteri(fn(index, elem){
///   print("(\(index),\(elem)) ")
/// }) //output: (0,1) (1,2) (2,3) (3,4) (4,5)
/// ```
pub fn iteri[T](self : Array[T], f : (Int,T) -> Unit) {
  let mut i = 0
  while i < self.length() {
    f(i,self[i])
    i = i + 1
  }
}

test "iteri" {
  let mut i = 0
  [1, 2, 3, 4, 5].iteri(fn(index, elem){
    @assertion.assert_eq(index,i)
    @assertion.assert_eq(elem,i+1)
    i = i + 1
  })
}

/// Applies a function to each element of the array and returns a new array with the results.
///
/// # Example
///
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// let doubled = arr.map(fn(x){ x * 2 })
/// debug(doubled) //output: [2, 4, 6, 8, 10]
/// ```
pub fn map[T,U](self : Array[T], f : (T) -> U) -> Array[U] {
  let res = Array::make(self.length(), f(self[0]))
  let mut i = 0
  while i < self.length() {
    res[i] = f(self[i])
    i = i + 1
  }
  res
}

test "map" {
  let arr = [1, 2, 3, 4, 5]
  let doubled = arr.map(fn(x){ x * 2 })
  @assertion.assert_eq(doubled,[2, 4, 6, 8, 10])
}

pub fn op_equal[T : Eq](self : Array[T], that : Array[T]) -> Bool {
  if self.length() != that.length() {
    return false
  }
  let mut i = 0
  while i < self.length() {
    if self[i] != that[i] {
      return false
    }
    i = i + 1
  }
  true
}

pub fn new[T](length : Int, value : () -> T) -> Array[T] {
  if length <= 0 {
    Array::default()
  } else {
    let array = Array::make(length, value())
    let mut i = 1
    while i < length, i = i + 1 {
      array[i] = value()
    }
    array
  }
}

pub fn newi[T](length: Int, value : (Int) -> T) -> Array[T] {
  if length <= 0 {
    Array::default()
  } else {
    let array = Array::make(length, value(0))
    let mut i = 1
    while i < length, i = i + 1 {
      array[i] = value(i)
    }
    array
  }
}
