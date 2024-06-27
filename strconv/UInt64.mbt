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

/// Pretend we have UInt64
priv type UInt64 Int64 derive(Eq)

fn new_UInt64_Int(value : Int) -> UInt64 {
  UInt64(value.to_int64())
}

fn UInt64::compare(self : UInt64, b : UInt64) -> Int {
  if self.0 >= 0L && b.0 >= 0L || self.0 < 0L && b.0 < 0L {
    self.0.compare(b.0)
  } else if self.0 < 0L { // b.0 >= 0
    1
  } else { // self.0 >= 0 && b.0 < 0
    -1
  }
}

fn op_add(self : UInt64, b : UInt64) -> UInt64 {
  UInt64(self.0 + b.0)
}

fn op_sub(self : UInt64, b : UInt64) -> UInt64 {
  UInt64(self.0 - b.0)
}

fn op_mul(self : UInt64, b : UInt64) -> UInt64 {
  UInt64(self.0 * b.0)
}

// fn op_div(self : UInt64, b : UInt64) -> UInt64 {
//   UInt64(self.0 / b.0)
// }

fn op_neg(self : UInt64) -> UInt64 {
  UInt64(-self.0)
}

fn lnot(self : UInt64) -> UInt64 {
  UInt64(self.0.lnot())
}

fn land(self : UInt64, b : UInt64) -> UInt64 {
  UInt64(self.0.land(b.0))
}

fn lor(self : UInt64, b : UInt64) -> UInt64 {
  UInt64(self.0.lor(b.0))
}

fn lxor(self : UInt64, b : UInt64) -> UInt64 {
  UInt64(self.0.lxor(b.0))
}

fn lsr(self : UInt64, b : Int) -> UInt64 {
  UInt64(self.0.lsr(b))
}

fn lsl(self : UInt64, b : Int) -> UInt64 {
  UInt64(self.0.lsl(b))
}

fn to_int64(self : UInt64) -> Int64 {
  self.0
}

fn to_double(self : UInt64) -> Double {
  if self.0 >= 0L {
    self.0.to_double()
  } else {
    Int64::max_value().to_double() + (self.0 - Int64::min_value()).to_double() +
    1.0
  }
}

/// Returns None if the multiplication might overflow (there are some false-negative corner cases).
/// Otherwise, returns Some(m), where m = self * b.
fn checked_mul(self : UInt64, b : UInt64) -> UInt64? {
  if self.0 == 0L || b.0 == 0L {
    return Some(UInt64(0L))
  }
  if self.0 == 1L {
    return Some(b)
  }
  if b.0 == 1L {
    return Some(self)
  }
  if b.0 < 0L || self.0 < 0L {
    return None
  }
  let r : UInt64 = UInt64(Int64::max_value() / b.0)
  let q : UInt64 = UInt64(1L / b.0)
  if r + r + q < self {
    return None
  }
  Some(self * b)
}

test "op_lt" {
  @assertion.assert_true(new_UInt64_Int(1) < new_UInt64_Int(2))!
  @assertion.assert_true(UInt64::UInt64(-1L) > UInt64(2L))!
}
