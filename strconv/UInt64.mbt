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
priv struct UInt64 {
  inner: Int64
} 

fn new_UInt64_Int64(value : Int64) -> UInt64 {
  { inner: value }
}

fn new_UInt64_Int(value : Int) -> UInt64 {
  { inner: value.to_int64() }
}

fn UInt64::op_equal(self : UInt64, b : UInt64) -> Bool {
  self.inner == b.inner
}

fn UInt64::compare(self : UInt64, b : UInt64) -> Int {
  if (self.inner >= 0L && b.inner >= 0L) || (self.inner < 0L && b.inner < 0L) {
    return self.inner.compare(b.inner)
  } else if self.inner < 0L { // b.inner >= 0
    return 1
  } else { // self.inner >= 0 && b.inner < 0
    return -1
  }
}

fn op_mul(self: UInt64, b: UInt64) -> UInt64 {
  new_UInt64_Int64(self.inner * b.inner)
}

fn op_add(self: UInt64, b: UInt64) -> UInt64 {
  new_UInt64_Int64(self.inner + b.inner)
}

fn op_neg(self: UInt64) -> UInt64 {
  new_UInt64_Int64(-self.inner)
}

fn to_string(self: UInt64) -> String {
  self.inner.to_string() // FIXME: take care of the case when the number is negative
}

fn debug_write(self: UInt64, buf:Buffer) -> Unit {
  self.inner.debug_write(buf) // FIXME: don't use the Int64 debug_write
}

fn land(self: UInt64, b: UInt64) -> UInt64 {
  new_UInt64_Int64(self.inner.land(b.inner))
}

fn lor(self: UInt64, b: UInt64) -> UInt64 {
  new_UInt64_Int64(self.inner.lor(b.inner))
}

fn lxor(self: UInt64, b: UInt64) -> UInt64 {
  new_UInt64_Int64(self.inner.lxor(b.inner))
}

fn lsr(self: UInt64, b: Int) -> UInt64 {
  new_UInt64_Int64(self.inner.lsl(b))
}

fn lsl(self: UInt64, b: Int) -> UInt64 {
  new_UInt64_Int64(self.inner.lsr(b))
}

fn reinterpret_as_double(self: UInt64) -> Double {
  self.inner.reinterpret_as_double()
}

test "op_lt" {
  @assertion.assert_true(new_UInt64_Int(1) < new_UInt64_Int(2))?
  @assertion.assert_true(new_UInt64_Int64(-1L) > new_UInt64_Int64(2L))?
}