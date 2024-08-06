// Copyright 2024 International Digital Economy Academy
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

/// create a reference from value
/// @alert deprecated "Use `new` instead"
pub fn ref[T](x : T) -> Ref[T] {
  { val: x }
}

/// create a reference from value
pub fn Ref::new[T](x : T) -> Ref[T] {
  { val: x }
}

pub fn to_string[X : Show](self : Ref[X]) -> String {
  let v = self.val
  "{val: \{v}}"
}

test "to_string" {
  inspect!(new(3), content="{val: 3}")
}

/// Maps the value of a `Ref` using a given function.
///
/// # Example
///
/// ```
/// debug(ref(1).map(fn(a){ a + 1 })) //output: ref(2)
/// ```
pub fn map[T, R](self : Ref[T], f : (T) -> R) -> Ref[R] {
  { val: f(self.val) }
}

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
/// ```
/// let x = ref(1)
/// x.protect(2, fn(){
///  debug(x) //output: ref(2)
///  x.val = 3
///  debug(x) //output: ref(3)  
/// })
/// debug(x) //output: ref(1)
/// ```
pub fn protect[T, R](self : Ref[T], a : T, f : () -> R) -> R {
  let old = self.val
  self.val = a
  let r = f()
  self.val = old
  r
}

/// Swaps the values of two references.
///
/// # Example
///
/// ```
/// let x = ref(1)
/// let y = ref(2)
/// swap(x, y)
/// debug(x) //output: ref(2)
/// debug(y) //output: ref(1)
/// ```
pub fn swap[T](self : Ref[T], that : Ref[T]) -> Unit {
  let tmp = self.val
  self.val = that.val
  that.val = tmp
}

test "swap" {
  let x = new(1)
  let y = new(2)
  swap(x, y)
  inspect!(x.val, content="2")
  inspect!(y.val, content="1")
}

pub fn update[T](self : Ref[T], f : (T) -> T) -> Unit {
  self.val = f(self.val)
}

test "decr" {
  let a = new(1)
  a.val -= 1
  inspect!(a.val, content="0")
  a.val -= 5
  inspect!(a.val, content="-5")
}

test "incr" {
  let a = new(1)
  a.val += 1
  inspect!(a.val, content="2")
  a.val += 5
  inspect!(a.val, content="7")
}
