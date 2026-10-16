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
// One callback processes 4096 values. The same harness runs on the old core.
fn float_bench_values(nans : Bool) -> Array[Double] {
  Array::makei(4096, i => {
    if nans && i % 16 == 0 {
      (0x7ff8000000000000UL + i.to_uint64()).reinterpret_as_double()
    } else {
      (i * 17 % 4096 - 2048).to_double() / 8.0
    }
  })
}

///|
test "Double comparison and hash kernels" (it : @bench.T) {
  for nans in [false, true] {
    let xs = float_bench_values(nans)
    let ys = xs.rev()
    let label = if nans { "nan-1-in-16" } else { "finite" }
    it.bench(name="Double eq \{label}", () => {
      let mut count = 0
      for i in 0..<xs.length() {
        count += (xs[i] == ys[i]).to_int()
      }
      it.keep(count)
    })
    it.bench(name="Double lt \{label}", () => {
      let mut count = 0
      for i in 0..<xs.length() {
        count += (xs[i] < ys[i]).to_int()
      }
      it.keep(count)
    })
    it.bench(name="Double compare \{label}", () => {
      let mut count = 0
      for i in 0..<xs.length() {
        count += xs[i].compare(ys[i])
      }
      it.keep(count)
    })
    it.bench(name="Double hash \{label}", () => {
      let mut hash = 0
      for x in xs {
        hash = hash ^ Hash::hash(x)
      }
      it.keep(hash)
    })
  }
}

///|
test "Float comparison and hash kernels" (it : @bench.T) {
  for nans in [false, true] {
    let xs = float_bench_values(nans).map(Float::from_double)
    let ys = xs.rev()
    let label = if nans { "nan-1-in-16" } else { "finite" }
    it.bench(name="Float eq \{label}", () => {
      let mut count = 0
      for i in 0..<xs.length() {
        count += (xs[i] == ys[i]).to_int()
      }
      it.keep(count)
    })
    it.bench(name="Float lt \{label}", () => {
      let mut count = 0
      for i in 0..<xs.length() {
        count += (xs[i] < ys[i]).to_int()
      }
      it.keep(count)
    })
    it.bench(name="Float compare \{label}", () => {
      let mut count = 0
      for i in 0..<xs.length() {
        count += xs[i].compare(ys[i])
      }
      it.keep(count)
    })
    it.bench(name="Float hash \{label}", () => {
      let mut hash = 0
      for x in xs {
        hash = hash ^ Hash::hash(x)
      }
      it.keep(hash)
    })
  }
}

///|
test "finite Double collection workloads and arithmetic control" (it : @bench.T) {
  let xs = float_bench_values(false)
  let map = Map(xs.mapi((i, x) => (x, i)))
  it.bench(name="Double sort finite", () => {
    let copy = xs.copy()
    copy.sort()
    it.keep(copy)
  })
  it.bench(name="Double map lookup finite", () => {
    let mut sum = 0
    for x in xs {
      sum += map[x]
    }
    it.keep(sum)
  })
  it.bench(name="Double arithmetic control", () => {
    let mut sum = 0.0
    for x in xs {
      sum += x * 0.125 + 1.0
    }
    it.keep(sum)
  })
}

///|
test "equality successful and mixed paths" (it : @bench.T) {
  for mode in ["equal-finite", "paired-nan", "mixed"] {
    let xs = float_bench_values(mode != "equal-finite")
    let ys = xs.mapi((i, x) => {
      if mode == "mixed" && i % 2 != 0 {
        xs[4095 - i]
      } else {
        x
      }
    })
    it.bench(name="Double eq \{mode}", () => {
      let mut count = 0
      for i in 0..<xs.length() {
        count += (xs[i] == ys[i]).to_int()
      }
      it.keep(count)
    })
    let fs = xs.map(Float::from_double)
    let gs = ys.map(Float::from_double)
    it.bench(name="Float eq \{mode}", () => {
      let mut count = 0
      for i in 0..<fs.length() {
        count += (fs[i] == gs[i]).to_int()
      }
      it.keep(count)
    })
  }
}
