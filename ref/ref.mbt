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
/// create a reference from value
pub fn[T] Ref::new(x : T) -> Ref[T] {
  { val: x }
}

///|
test "to_string" {
  inspect(new(3), content="{val: 3}")
}

///|
/// same as `Ref::new`
pub fn[T] new(x : T) -> Ref[T] {
  { val: x }
}

///|
/// Maps the value of a `Ref` using a given function.
///
/// # Example
///
/// ```mbt
///   assert_eq(@ref.new(1).map((a) => { a + 1 }).val, 2)
/// ```
pub fn[T, R] map(self : Ref[T], f : (T) -> R raise?) -> Ref[R] raise? {
  { val: f(self.val) }
}

///|
/// This function allows you to temporarily replace the value of a reference with a new value,
/// execute a given function, and then restore the original value of the reference.
///
/// # Arguments
///
/// - `self`: The reference whose value will be temporarily replaced.
/// - `a`: The new value to assign to the reference.
/// - `f`: The function to execute while the reference value is replaced.
///
/// # Returns
///
/// The result of executing the provided function `f`.
///
/// # Example
///
/// ```mbt
///   let x = @ref.new(1)
///   x.protect(2, () => { x.val = 3 })
///   assert_eq(x.val, 1)
/// ```
pub fn[T, R] protect(self : Ref[T], a : T, f : () -> R raise?) -> R raise? {
  let old = self.val
  self.val = a
  try f() catch {
    err => {
      self.val = old
      raise err
    }
  } noraise {
    r => {
      self.val = old
      r
    }
  }
}

///|
/// Swaps the values of two references.
///
/// # Example
///
/// ```mbt
///   let x = @ref.new(1)
///   let y = @ref.new(2)
///   @ref.swap(x, y)
///   assert_eq(x.val, 2)
///   assert_eq(y.val, 1)
/// ```
#as_free_fn
pub fn[T] Ref::swap(self : Ref[T], that : Ref[T]) -> Unit {
  let tmp = self.val
  self.val = that.val
  that.val = tmp
}

///|
test "swap" {
  let x = new(1)
  let y = new(2)
  swap(x, y)
  inspect(x.val, content="2")
  inspect(y.val, content="1")
}

///|
pub fn[T] update(self : Ref[T], f : (T) -> T raise?) -> Unit raise? {
  self.val = f(self.val)
}

///|
test "decr" {
  let a = new(1)
  a.val -= 1
  inspect(a.val, content="0")
  a.val -= 5
  inspect(a.val, content="-5")
}

///|
test "incr" {
  let a = new(1)
  a.val += 1
  inspect(a.val, content="2")
  a.val += 5
  inspect(a.val, content="7")
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for Ref[X] with arbitrary(
  size,
  rs,
) {
  new(X::arbitrary(size, rs))
}
