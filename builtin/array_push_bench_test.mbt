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
let array_push_bench_size = 200_000

///|
priv struct ArrayPushBenchStruct {
  x : Int
  y : Int
}

///|
fn make_array_push_bench_pairs() -> FixedArray[(Int, Int)] {
  FixedArray::makei(array_push_bench_size, i => (i, i + 1))
}

///|
fn make_array_push_bench_structs() -> FixedArray[ArrayPushBenchStruct] {
  FixedArray::makei(array_push_bench_size, i => { x: i, y: i + 1 })
}

///|
test "bench Array::push Int preallocated n=200000" (it : @bench.T) {
  it.bench(
    fn() {
      let arr = Array::new(capacity=array_push_bench_size)
      for i in 0..<array_push_bench_size {
        arr.push(i)
      }
      it.keep(arr)
    },
    count=20,
  )
}

///|
test "bench Array::push Int growing n=200000" (it : @bench.T) {
  it.bench(
    fn() {
      let arr : Array[Int] = []
      for i in 0..<array_push_bench_size {
        arr.push(i)
      }
      it.keep(arr)
    },
    count=20,
  )
}

///|
test "bench Array::push tuple preallocated n=200000" (it : @bench.T) {
  let values = make_array_push_bench_pairs()
  it.bench(
    fn() {
      let arr = Array::new(capacity=array_push_bench_size)
      for i in 0..<array_push_bench_size {
        arr.push(values[i])
      }
      it.keep(arr)
    },
    count=20,
  )
}

///|
test "bench Array::push struct preallocated n=200000" (it : @bench.T) {
  let values = make_array_push_bench_structs()
  let first = values[0]
  it.keep(first.x + first.y)
  it.bench(
    fn() {
      let arr = Array::new(capacity=array_push_bench_size)
      for i in 0..<array_push_bench_size {
        arr.push(values[i])
      }
      it.keep(arr)
    },
    count=20,
  )
}
