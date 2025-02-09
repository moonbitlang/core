// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
impl Clone for Unit with mutability() { Immutable }

///|
impl Clone for Unit with clone(self) { self }

///|
impl Clone for Bool with mutability() { Immutable }

///|
impl Clone for Bool with clone(self) { self }

///|
impl Clone for Int with mutability() { Immutable }

///|
impl Clone for Int with clone(self) { self }

///|
impl Clone for Int64 with mutability() { Immutable }

///|
impl Clone for Int64 with clone(self) { self }

///|
impl Clone for UInt with mutability() { Immutable }

///|
impl Clone for UInt with clone(self) { self }

///|
impl Clone for Byte with mutability() { Immutable }

///|
impl Clone for Byte with clone(self) { self }

///|
impl Clone for String with mutability() { Immutable }

///|
impl Clone for String with clone(self) { self }

// mutable containers

///|
fn copy_array[T](self : Array[T]) -> Array[T] {
  let len = self.length()
  if len == 0 {
    []
  } else {
    let arr = Array::make(len, self[0])
    Array::unsafe_blit(arr, 0, self, 0, len)
    arr
  }
}

///|
impl[T : Clone] Clone for Array[T] with mutability() { Mutable }

///|
impl[T : Clone] Clone for Array[T] with clone(self) {
  match T::mutability() {
    Mutable => self.map(T::clone)
    Immutable => self.copy_array()
  }
}

test "Array[Int]::clone" {
  let xs = [1, 2, 3, 4, 5]
  let ys = xs.clone()
  xs[0] = 99
  inspect!(xs, content="[99, 2, 3, 4, 5]")
  inspect!(ys, content="[1, 2, 3, 4, 5]")
}

test "Array[Ref[Int]]::clone" {
  let xs = [1, 2, 3, 4, 5].map(fn(x) { { val: x } })
  let ys = xs.clone()
  xs[0].val = 99
  inspect!(xs, content="[{val: 99}, {val: 2}, {val: 3}, {val: 4}, {val: 5}]")
  inspect!(ys, content="[{val: 1}, {val: 2}, {val: 3}, {val: 4}, {val: 5}]")
}

///|
impl[T : Clone] Clone for FixedArray[T] with mutability() { Mutable }

///|
fn map_fixedarray[T, U](self : FixedArray[T], f : (T) -> U) -> FixedArray[U] {
  if self.length() == 0 {
    return []
  }
  let res = FixedArray::make(self.length(), f(self[0]))
  for i = 1; i < self.length(); i = i + 1 {
    res[i] = f(self[i])
  }
  res
}

///|
impl[T : Clone] Clone for FixedArray[T] with clone(self) {
  match T::mutability() {
    Mutable => self.map_fixedarray(T::clone)
    Immutable => self.map_fixedarray(fn(x) { x })
  }
}

test "FixedArray[Int]::clone" {
  let xs : FixedArray[Int] = [1, 2, 3, 4, 5]
  let ys = xs.clone()
  xs[0] = 99
  inspect!(xs, content="[99, 2, 3, 4, 5]")
  inspect!(ys, content="[1, 2, 3, 4, 5]")
}

test "FixedArray[Ref[Int]]::clone" {
  let xs = ([1, 2, 3, 4, 5] : FixedArray[Int]).map_fixedarray(fn(x) {
    { val: x }
  })
  let ys = xs.clone()
  xs[0].val = 99
  inspect!(xs, content="[{val: 99}, {val: 2}, {val: 3}, {val: 4}, {val: 5}]")
  inspect!(ys, content="[{val: 1}, {val: 2}, {val: 3}, {val: 4}, {val: 5}]")
}

///|
impl[T : Clone] Clone for Ref[T] with mutability() { Mutable }

///|
impl[T : Clone] Clone for Ref[T] with clone(self) {
  match T::mutability() {
    Mutable => { val: T::clone(self.val) }
    Immutable => { val: self.val }
  }
}

test "Ref[Int]::clone" {
  let x = { val: 0 }
  let y = x.clone()
  x.val = 10
  inspect!(x, content="{val: 10}")
  inspect!(y, content="{val: 0}")
}

///|
impl Clone for Bytes with mutability() { Mutable }

///|
impl Clone for Bytes with clone(self) { self.copy() }

test "Bytes::clone" {
  let xs = b"\x12\x34"
  let ys = xs.clone()
  xs[0] = b'\x00'
  let xss =
    #|b"\x00\x34"
  let yss =
    #|b"\x12\x34"
  inspect!(xs, content=xss)
  inspect!(ys, content=yss)
}

// immutable containers

///|
impl[T : Clone] Clone for T? with mutability() { T::mutability() }

///|
impl[T : Clone] Clone for T? with clone(self) {
  match T::mutability() {
    Mutable =>
      match self {
        Some(x) => Some(T::clone(x))
        None => None
      }
    Immutable => self
  }
}

test "Ref[Int]?::clone" {
  let x = Some({ val: 0 })
  let y = x.clone()
  x.unwrap().val = 99
  inspect!(x, content="Some({val: 99})")
  inspect!(y, content="Some({val: 0})")
}

///|
impl[T : Clone, E : Clone] Clone for Result[T, E] with mutability() {
  match (T::mutability(), E::mutability()) {
    (Immutable, Immutable) => Immutable
    _ => Mutable
  }
}

///|
impl[T : Clone, E : Clone] Clone for Result[T, E] with clone(self) {
  match T::mutability() {
    Mutable =>
      match self {
        Ok(x) => Ok(T::clone(x))
        Err(x) => Err(E::clone(x))
      }
    Immutable => self
  }
}

test "Result[Ref[Int],Ref[String]]::clone" {
  let x : Result[Ref[Int], Ref[String]] = Ok({ val: 1 })
  let y = x.clone()
  match x {
    Ok(x) => x.val = 99
    Err(x) => x.val = "OvO"
  }
  inspect!(x, content="Ok({val: 99})")
  inspect!(y, content="Ok({val: 1})")
  let x : Result[Ref[Int], Ref[String]] = Err({ val: "mooncake" })
  let y = x.clone()
  match x {
    Ok(x) => x.val = 99
    Err(x) => x.val = "OvO"
  }
  inspect!(x, content="Err({val: \"OvO\"})")
  inspect!(y, content="Err({val: \"mooncake\"})")
}

///|
fn get_mutability[T : Clone](_ : T) -> Mutability {
  T::mutability()
}

test "mutability" {

  // immutable 
  let oi = Some(0)
  inspect!(get_mutability(oi), content="Immutable")
  let ris : Result[Int, String] = Ok(32)
  inspect!(get_mutability(ris), content="Immutable")
  // TODO, we need to test reference equal

  // mutable 
  let ri : Ref[Int] = { val: 0 }
  let ari = [ri]
  let aoi = [oi]
  inspect!(get_mutability(ri), content="Mutable")
  inspect!(get_mutability(ari), content="Mutable")
  inspect!(get_mutability(aoi), content="Mutable")
}
