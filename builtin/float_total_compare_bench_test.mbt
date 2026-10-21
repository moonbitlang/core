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

// Each timed call compares 1,024 pairs. Keep input creation outside timing and
// consume outputs once per batch, so keep/closure overhead is amortized.

///|
fn total_compare_inputs(
  kind : Int32,
) -> (FixedArray[Double], FixedArray[Double]) {
  let mut state = 0x4d595df4d0f33173UL
  let a = FixedArray::make(1024, 0.0)
  let b = FixedArray::make(1024, 0.0)
  for i in 0..<1024 {
    state = state * 6364136223846793005UL + 1442695040888963407UL
    a[i] = if kind == 2 {
      state.reinterpret_as_double()
    } else {
      state.reinterpret_as_int64().to_double()
    }
    state = state * 6364136223846793005UL + 1442695040888963407UL
    b[i] = if kind == 2 {
      state.reinterpret_as_double()
    } else {
      state.reinterpret_as_int64().to_double()
    }
    if i % 4 == 0 {
      b[i] = a[i]
    }
    if kind == 1 {
      if i % 4 == 0 {
        a[i] = @double.not_a_number
      }
      if i % 4 == 1 {
        b[i] = @double.not_a_number
      }
    }
  }
  (a, b)
}

///|
test "bench Double::total_compare" (it : @bench.T) {
  for kind in 0..<3 {
    let (da, db) = total_compare_inputs(kind)
    let (a, b) = (da, db)
    let output = FixedArray::make(1024, 0)
    let label = ["finite", "nan-heavy", "random-bits"][kind]
    it.bench(name="double store \{label}", fn() {
      for i in 0..<1024 {
        output[i] = a[i].total_compare(b[i]) + 1
      }
      it.keep(output)
    })
    it.bench(name="double sum \{label}", fn() {
      let mut sum = 0
      for i in 0..<1024 {
        sum += a[i].total_compare(b[i]) + 1
      }
      it.keep(sum)
    })
  }
}

///|
test "bench Float::total_compare" (it : @bench.T) {
  for kind in 0..<3 {
    let (da, db) = total_compare_inputs(kind)
    let a = da.map(x => {
      if kind == 2 {
        Float::reinterpret_from_uint(x.reinterpret_as_uint64().to_uint())
      } else {
        Float::from_double(x)
      }
    })
    let b = db.map(x => {
      if kind == 2 {
        Float::reinterpret_from_uint(x.reinterpret_as_uint64().to_uint())
      } else {
        Float::from_double(x)
      }
    })
    let output = FixedArray::make(1024, 0)
    let label = ["finite", "nan-heavy", "random-bits"][kind]
    it.bench(name="float store \{label}", fn() {
      for i in 0..<1024 {
        output[i] = a[i].total_compare(b[i]) + 1
      }
      it.keep(output)
    })
    it.bench(name="float sum \{label}", fn() {
      let mut sum = 0
      for i in 0..<1024 {
        sum += a[i].total_compare(b[i]) + 1
      }
      it.keep(sum)
    })
  }
}
