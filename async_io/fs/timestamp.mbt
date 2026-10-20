// Copyright 2026 International Digital Economy Academy
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
#valtype
struct Timestamp {
  sec : Int64
  nsec : Int32
} derive(Eq, Compare, @debug.Debug)

///|
/// Return the number of seconds since Unix EPOCH of the timestamp
pub fn Timestamp::sec(ts : Timestamp) -> Int64 {
  ts.sec
}

///|
/// Return the number of milli-seconds since Unix EPOCH of the timestamp
pub fn Timestamp::msec(ts : Timestamp) -> Int64 {
  ts.sec * 1000 + ts.nsec.to_int64() / 1_000_000
}

///|
/// Return the (sub-second) nanosecond part of a timestamp
pub fn Timestamp::nsec(ts : Timestamp) -> Int32 {
  ts.nsec
}

///|
pub impl Sub for Timestamp with fn sub(x, y) {
  if x.nsec >= y.nsec {
    { sec: x.sec - y.sec, nsec: x.nsec - y.nsec, }
  } else {
    { sec: x.sec - y.sec - 1, nsec: 1_000_000_000 - y.nsec + x.nsec, }
  }
}
