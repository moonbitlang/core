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

///-----------------------------------------------------------------------------
/// Creates an iterator that iterates over a range of Int with default step 1.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Int from `start` to `end - 1`.
/// @alert deprecated "Use `..<` in for loop or `until` method instead"
pub fn upto(self : Int, end : Int, ~inclusive : Bool = false) -> Iter[Int] {
  fn(yield) {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield(i) == IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///-----------------------------------------------------------------------------
/// Creates an iterator that iterates over a range of UInt with default step 1U.
/// 
/// # Arguments
/// 
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
/// 
/// Returns an iterator that iterates over the range of UInt from `start` to `end - 1`.
/// @alert deprecated "Use `..<` in for loop or `until` method instead"
pub fn upto(self : UInt, end : UInt, ~inclusive : Bool = false) -> Iter[UInt] {
  fn(yield) {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield(i) == IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///-----------------------------------------------------------------------------
/// Creates an iterator that iterates over a range of UInt64 with default step 1UL.
/// 
/// # Arguments
/// 
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
/// 
/// # Returns
/// 
/// Returns an iterator that iterates over the range of UInt64 from `start` to `end - 1`.
/// @alert deprecated "Use `..<` in for loop or `until` method instead"
pub fn upto(
  self : UInt64,
  end : UInt64,
  ~inclusive : Bool = false
) -> Iter[UInt64] {
  fn(yield) {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield(i) == IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///-----------------------------------------------------------------------------
/// Creates an iterator that iterates over a range of Int64 with default step 1L.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Int64 from `start` to `end - 1`.
/// @alert deprecated "Use `..<` in for loop or `until` method instead"
pub fn upto(
  self : Int64,
  end : Int64,
  ~inclusive : Bool = false
) -> Iter[Int64] {
  fn(yield) {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield(i) == IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///-----------------------------------------------------------------------------
/// Creates an iterator that iterates over a range of Float with default step 1.0 .
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Float from `start` to `end - 1`.
/// @alert deprecated "Use `..<` in for loop or `until` method instead"
pub fn upto(
  self : Float,
  end : Float,
  ~inclusive : Bool = false
) -> Iter[Float] {
  fn(yield) {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield(i) == IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///-----------------------------------------------------------------------------
/// Creates an iterator that iterates over a range of Double with default step 1.0 .
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Double from `start` to `end - 1`.
/// @alert deprecated "Use `..<` in for loop or `until` method instead"
pub fn upto(
  self : Double,
  end : Double,
  ~inclusive : Bool = false
) -> Iter[Double] {
  fn(yield) {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield(i) == IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}
