// This example implements an imperative vector data structure in MoonBit,
// which support `O(1)` random access and amortized `O(1)` `push`/`pop` operations

pub struct Vector[X] {
  mut data : Array[X]
  mut len : Int
}

/// `to_string[X : Show](self : Vector[X]) -> String`
///
/// convert a vector to string, type inside the vector must have method `to_string`
pub fn to_string[T : Show](self : Vector[T]) -> String {
  let mut str = "Vec["
  let n = self.length()
  for i = 0; i <= n; i = i + 1 {
    str = str + match self[i] {
        Some(x) => if i != n - 1 { x.to_string() + "," } else { x.to_string() }
        None => "]"
      }
  }
  str
}

// `from_array[X](arr : Array[X]) -> Vector[X]`
pub fn Vector::from_array[X](arr : Array[X]) -> Vector[X] {
  return { data: arr, len: arr.length() }
}

pub fn iter[T](self : Vector[T], f : (T) -> Unit) {
  for i = 0; i < self.len; i = i + 1 {
    f(self.data[i])
  }
}

pub fn iteri[T](self : Vector[T], f : (Int, T) -> Unit) {
  for i = 0; i < self.len; i = i + 1 {
    f(i, self.data[i])
  }
}

/// `length[X](self : Vector[X])`
///
/// Get length of a vector
pub fn length[X](self : Vector[X]) -> Int {
  self.len
}

/// `capacity[X](self : Vector[X])`
///
/// Get capacity of a vector
fn capacity[X](self : Vector[X]) -> Int {
  self.data.length()
}

fn grow_amortized[X](self : Vector[X], additional : Int) {
  if self.len + additional > self.capacity() {
    let new_cap = if self.capacity() < 2 { 4 } else { self.capacity() * 2 }
    self.data = Array::make(new_cap, self.data[0])
  }
}

/// `Vector::new_with_default[X](len : Int, default : X)`
///
/// Create a vector with length `len`, filling with value `default`
pub fn Vector::new_with_default[X](len : Int, default : X) -> Vector[X] {
  let cap = if len < 4 { 4 } else { len }
  { data: Array::make(cap, default), len }
}

/// Vector::new[X : Default](len : Int)
///
/// Create a vector with length `len`, filling with default value of type `X`
pub fn Vector::new[X : Default](len : Int) -> Vector[X] {
  Vector::new_with_default(len, X::default())
}

/// `op_get[X](self : Vector[X], i : Int)`
///
/// Get the ith element of vector
pub fn op_get[X](self : Vector[X], i : Int) -> Option[X] {
  if i < self.len {
    Some(self.data[i])
  } else {
    None
  }
}

/// push_back_with_default[X](self : Vector[X], elem : X, default : X)
///
/// Push back `elem` to a vector, `default` will be used to fill the additional space
pub fn push_back_with_default[X](self : Vector[X], elem : X, default : X) {
  if self.len < self.capacity() {
    self.data[self.len] = elem
    self.len = self.len + 1
  } else {
    let old_cap = self.capacity()
    let new_cap = if old_cap == 0 { 4 } else { old_cap * 2 }
    let new_data = Array::make(new_cap, default)
    for i = 0; i < self.len; i = i + 1 {
      new_data[i] = self.data[i]
    }
    new_data[self.len] = elem
    self.data = new_data
    self.len = self.len + 1
  }
}

/// push_back[X : Default](self : Vector[X], elem : X)
///
/// Push back `elem` to a vector, default value of type `X` will be used to fill the additional space
pub fn push_back[X : Default](self : Vector[X], elem : X) {
  self.push_back_with_default(elem, X::default())
}

test "Vector to_string" {
  let v = Vector::new_with_default(3, 0)
  v.push_back(1)
  v.push_back(2)
  v.push_back(3)
  if v.to_string() != "Vec[0,0,0,1,2,3]" {
    return Err(
      "Vector to_string failed, left: " + v.to_string() + ", right: Vec[1,2,3]",
    )
  }
}

test "Vector iter" {
  let v = Vector::[0, 0, 0, 1, 2, 3]
  let mut sum = 0
  v.iter(fn(x) { sum = x + sum })
  if sum != 6 {
    return Err("Vector iter failed")
  }
}

test "Vector iteri" {
  let v = Vector::[0, 1, 2, 3]
  let mut failed = false
  v.iteri(fn(i, x) { if i != x { failed = true; print(i); print(x) } })
  if failed {
    return Err("Vector iteri index failed")
  }
}

test "Vector length" {
  let v = Vector::new_with_default(3, 0)
  v.push_back(1)
  v.push_back(2)
  v.push_back(3)
  if v.length() != 6 {
    return Err("Vector length failed")
  }
}

test "Vector capacity" {
  let v = Vector::new_with_default(3, 0)
  if v.capacity() != 4 {
    return Err("Vector capacity failed")
  }
}

test "Vector push_back_with_default" {
  let v = Vector::new_with_default(4, 0)
  v.push_back_with_default(1, 2)
  if v.length() != 5 || v[4] != Some(1) {
    return Err("Vector push_back_with_default failed")
  }
}

test "Vector push_back" {
  let v = Vector::new_with_default(3, 0)
  v.push_back(1)
  if v.length() != 4 || v[3] != Some(1) {
    return Err("Vector push_back failed")
  }
}

test "Vector op_get" {
  let v = Vector::new_with_default(0, 0)
  v.push_back(1)
  v.push_back(2)
  v.push_back(3)
  if v[1] != Some(2) {
    return Err("Vector op_get failed")
  }
  if v[3] != None {
    return Err("Vector op_get failed for out-of-bounds index")
  }
}
